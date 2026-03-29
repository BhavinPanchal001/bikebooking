import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight user info stored inside a chat document
/// to avoid extra reads when rendering the messages list.
class ChatParticipant {
  const ChatParticipant({
    required this.name,
    this.photoUrl = '',
    this.phoneNumber = '',
  });

  final String name;
  final String photoUrl;
  final String phoneNumber;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
    };
  }

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      name: map['name']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
    );
  }
}

/// Snapshot of the product that triggered this conversation.
class ProductSnapshot {
  const ProductSnapshot({
    required this.productId,
    required this.title,
    this.price,
    this.imageUrl = '',
  });

  final String productId;
  final String title;
  final double? price;
  final String imageUrl;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory ProductSnapshot.fromMap(Map<String, dynamic> map) {
    return ProductSnapshot(
      productId: map['productId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble(),
      imageUrl: map['imageUrl']?.toString() ?? '',
    );
  }
}

/// Denormalized copy of the most recent message,
/// stored on the chat document for the conversation list.
class LastMessage {
  const LastMessage({
    required this.text,
    required this.senderId,
    this.timestamp,
    this.type = 'text',
  });

  final String text;
  final String senderId;
  final DateTime? timestamp;
  final String type;

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
    };
  }

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      type: map['type']?.toString() ?? 'text',
    );
  }
}

/// Represents a single conversation document in the `chats` collection.
class ChatModel {
  const ChatModel({
    this.id,
    required this.participants,
    required this.participantDetails,
    this.productSnapshot,
    this.lastMessage,
    this.unreadCount = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final List<String> participants;
  final Map<String, ChatParticipant> participantDetails;
  final ProductSnapshot? productSnapshot;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Returns the other participant's ID given the current user's ID.
  String otherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Returns the other participant's details.
  ChatParticipant? otherParticipantDetails(String currentUserId) {
    return participantDetails[otherParticipantId(currentUserId)];
  }

  /// Returns unread count for a specific user.
  int unreadCountFor(String userId) => unreadCount[userId] ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantDetails': participantDetails.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      if (productSnapshot != null)
        'productSnapshot': productSnapshot!.toMap(),
      if (lastMessage != null) 'lastMessage': lastMessage!.toMap(),
      'unreadCount': unreadCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Parse participantDetails
    final detailsRaw = map['participantDetails'];
    final participantDetails = <String, ChatParticipant>{};
    if (detailsRaw is Map) {
      for (final entry in detailsRaw.entries) {
        final key = entry.key.toString();
        if (entry.value is Map) {
          participantDetails[key] = ChatParticipant.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    // Parse unreadCount
    final unreadRaw = map['unreadCount'];
    final unreadCount = <String, int>{};
    if (unreadRaw is Map) {
      for (final entry in unreadRaw.entries) {
        unreadCount[entry.key.toString()] =
            (entry.value as num?)?.toInt() ?? 0;
      }
    }

    // Parse productSnapshot
    final productRaw = map['productSnapshot'];
    ProductSnapshot? productSnapshot;
    if (productRaw is Map) {
      productSnapshot = ProductSnapshot.fromMap(
        Map<String, dynamic>.from(productRaw),
      );
    }

    // Parse lastMessage
    final lastRaw = map['lastMessage'];
    LastMessage? lastMessage;
    if (lastRaw is Map) {
      lastMessage = LastMessage.fromMap(Map<String, dynamic>.from(lastRaw));
    }

    return ChatModel(
      id: documentId,
      participants: List<String>.from(map['participants'] ?? []),
      participantDetails: participantDetails,
      productSnapshot: productSnapshot,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
