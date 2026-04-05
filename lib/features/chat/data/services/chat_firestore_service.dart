import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:bikebooking/features/chat/data/models/chat_model.dart';
import 'package:bikebooking/features/chat/data/models/message_model.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';

class ChatFirestoreService {
  ChatFirestoreService({
    FirebaseFirestore? firestore,
    SellerActionFirestoreService? sellerActionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService();

  final FirebaseFirestore _firestore;
  final SellerActionFirestoreService _sellerActionService;

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // ---------------------------------------------------------------------------
  // Get or Create Chat
  // ---------------------------------------------------------------------------

  /// Finds an existing chat between two users about a specific product,
  /// or creates a new one if none exists.
  ///
  /// Returns the chat document ID.
  Future<String> getOrCreateChat({
    required AppUserModel currentUser,
    required AppUserModel otherUser,
    required ProductModel product,
  }) async {
    final currentUserId = currentUser.id;
    final otherUserId = otherUser.id;
    final productId = product.id ?? '';

    await _assertUsersCanChat(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );

    // Search for an existing chat with both participants AND same product.
    final querySnapshot = await _chatsRef
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      final existingProductSnapshot = data['productSnapshot'];
      final existingProductId = (existingProductSnapshot is Map)
          ? existingProductSnapshot['productId']?.toString() ?? ''
          : '';

      if (participants.contains(otherUserId) &&
          existingProductId == productId) {
        return doc.id;
      }
    }

    // No existing chat found — create a new one.
    final chat = ChatModel(
      participants: [currentUserId, otherUserId],
      participantDetails: {
        currentUserId: ChatParticipant(
          name: currentUser.displayName,
          photoUrl: currentUser.photoUrl,
          phoneNumber: currentUser.phoneNumber,
        ),
        otherUserId: ChatParticipant(
          name: otherUser.displayName,
          photoUrl: otherUser.photoUrl,
          phoneNumber: otherUser.phoneNumber,
        ),
      },
      productSnapshot: ProductSnapshot(
        productId: productId,
        title: product.title,
        price: product.price,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
      ),
      unreadCount: {currentUserId: 0, otherUserId: 0},
    );

    final docRef = await _chatsRef.add(chat.toMap());
    return docRef.id;
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Real-time stream of all conversations for a user,
  /// ordered by most recent activity.
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final hiddenUserIds = await _loadHiddenUserIds(userId);
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .where(
            (chat) =>
                !hiddenUserIds.contains(chat.otherParticipantId(userId).trim()),
          )
          .toList();

      chats.sort((first, second) {
        final secondTimestamp = second.updatedAt ??
            second.lastMessage?.timestamp ??
            second.createdAt;
        final firstTimestamp =
            first.updatedAt ?? first.lastMessage?.timestamp ?? first.createdAt;

        if (firstTimestamp == null && secondTimestamp == null) {
          return 0;
        }
        if (secondTimestamp == null) {
          return -1;
        }
        if (firstTimestamp == null) {
          return 1;
        }

        return secondTimestamp.compareTo(firstTimestamp);
      });

      return chats;
    });
  }

  /// Real-time stream of messages for a specific chat,
  /// ordered chronologically (oldest first).
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Send Message
  // ---------------------------------------------------------------------------

  /// Sends a chat message and updates the chat document's
  /// `lastMessage`, `unreadCount`, and `updatedAt`.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String type = 'text',
    String? imageUrl,
    String? previewText,
    String? otherUserId,
    String? clientMessageId,
    DateTime? sentAt,
    bool verifyChatAvailability = true,
  }) async {
    final trimmedText = text.trim();
    final normalizedType =
        type.trim().isEmpty ? 'text' : type.trim().toLowerCase();
    final normalizedImageUrl = imageUrl?.trim() ?? '';
    final normalizedPreviewText = previewText?.trim() ?? '';
    if (normalizedType == 'image' && normalizedImageUrl.isEmpty) {
      throw ArgumentError('An image URL is required for image messages.');
    }
    if (normalizedType != 'image' && trimmedText.isEmpty) return;

    final normalizedClientMessageId = clientMessageId?.trim() ?? '';
    final localSentAt = sentAt ?? DateTime.now();
    var resolvedOtherUserId = otherUserId?.trim() ?? '';
    final resolvedPreviewText = normalizedPreviewText.isNotEmpty
        ? normalizedPreviewText
        : normalizedType == 'image'
            ? (trimmedText.isEmpty ? 'Photo' : 'Photo: $trimmedText')
            : trimmedText;

    if (resolvedOtherUserId.isEmpty) {
      final chatDoc = await _chatsRef.doc(chatId).get();
      final chatData = chatDoc.data();
      if (!chatDoc.exists || chatData == null) {
        throw StateError('Conversation not found.');
      }

      final participants = List<String>.from(chatData['participants'] ?? []);
      resolvedOtherUserId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );
    }

    if (verifyChatAvailability) {
      await _assertUsersCanChat(
        currentUserId: senderId,
        otherUserId: resolvedOtherUserId,
      );
    }

    final message = MessageModel(
      clientMessageId:
          normalizedClientMessageId.isEmpty ? null : normalizedClientMessageId,
      senderId: senderId,
      text: trimmedText,
      type: normalizedType,
      imageUrl: normalizedImageUrl.isEmpty ? null : normalizedImageUrl,
      timestamp: localSentAt,
      readBy: [senderId],
    );

    // Add message to the sub-collection.
    await _chatsRef.doc(chatId).collection('messages').add(message.toMap());

    // Update the chat document with last message and increment unread.
    final updates = <String, dynamic>{
      'lastMessage': {
        'text': resolvedPreviewText,
        'senderId': senderId,
        'timestamp': Timestamp.fromDate(localSentAt),
        'type': normalizedType,
        if (normalizedClientMessageId.isNotEmpty)
          'clientMessageId': normalizedClientMessageId,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (resolvedOtherUserId.isNotEmpty) {
      updates['unreadCount.$resolvedOtherUserId'] = FieldValue.increment(1);
    }

    await _chatsRef.doc(chatId).update(updates);
  }

  // ---------------------------------------------------------------------------
  // Read Receipts
  // ---------------------------------------------------------------------------

  /// Marks all unread messages in this chat as read by `userId`,
  /// and resets `unreadCount` for that user.
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    // Reset the user's unread count on the chat document.
    await _chatsRef.doc(chatId).update({
      'unreadCount.$userId': 0,
    });

    // Batch update all messages not yet read by this user.
    final unreadMessages = await _chatsRef
        .doc(chatId)
        .collection('messages')
        .where('readBy', whereNotIn: [
      [userId]
    ]).get();

    if (unreadMessages.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Online Status
  // ---------------------------------------------------------------------------

  /// Sets a user's online status and last seen timestamp.
  Future<void> updateUserOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    await _usersRef.doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Streams another user's online status and last seen time.
  Stream<Map<String, dynamic>> getUserOnlineStatus(String userId) {
    return _usersRef.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return {
        'isOnline': data?['isOnline'] ?? false,
        'lastSeen': (data?['lastSeen'] as Timestamp?)?.toDate(),
      };
    });
  }

  // ---------------------------------------------------------------------------
  // Fetch Single Chat
  // ---------------------------------------------------------------------------

  /// Fetches a single chat document by ID.
  Future<ChatModel?> getChatById(String chatId) async {
    final doc = await _chatsRef.doc(chatId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ChatModel.fromMap(doc.data()!, doc.id);
  }

  // ---------------------------------------------------------------------------
  // Total Unread Count
  // ---------------------------------------------------------------------------

  /// Streams the total unread message count across all chats for a user.
  Stream<int> getTotalUnreadCount(String userId) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final hiddenUserIds = await _loadHiddenUserIds(userId);
      int total = 0;
      for (final doc in snapshot.docs) {
        final participants =
            List<String>.from(doc.data()['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );
        if (hiddenUserIds.contains(otherUserId.trim())) {
          continue;
        }

        final unread = doc.data()['unreadCount'];
        if (unread is Map && unread[userId] != null) {
          total += (unread[userId] as num).toInt();
        }
      }
      return total;
    });
  }

  Future<void> _assertUsersCanChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final normalizedCurrentUserId = currentUserId.trim();
    final normalizedOtherUserId = otherUserId.trim();
    if (normalizedCurrentUserId.isEmpty || normalizedOtherUserId.isEmpty) {
      return;
    }

    final hasBlockingRelationship =
        await _sellerActionService.hasBlockingRelationship(
      firstUserId: normalizedCurrentUserId,
      secondUserId: normalizedOtherUserId,
    );
    if (hasBlockingRelationship) {
      throw const UserBlockException(
        'This conversation is unavailable because one of you has blocked the other.',
      );
    }
  }

  Future<Set<String>> _loadHiddenUserIds(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return <String>{};
    }

    try {
      return await _sellerActionService.getHiddenUserIds(normalizedUserId);
    } catch (_) {
      return <String>{};
    }
  }
}
