import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/chat/data/models/chat_model.dart';
import 'package:bikebooking/features/chat/presentation/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // ignore: unused_field
  late final ChatController _chatController;
  late final bool _ownsChatController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ChatController>()) {
      _chatController = Get.find<ChatController>();
      _ownsChatController = false;
    } else {
      _chatController = Get.put(ChatController());
      _ownsChatController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsChatController && Get.isRegistered<ChatController>()) {
      Get.delete<ChatController>();
    }
    super.dispose();
  }

  String get _currentUserId {
    final loginController = Get.find<LoginController>();
    return loginController.chatUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with Gradient
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 50, bottom: 30, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A5F82), AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: GetBuilder<ChatController>(
              builder: (controller) {
                if (controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF233A66),
                    ),
                  );
                }

                if (controller.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            controller.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF5E6E8C),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: controller.reloadChats,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (controller.chats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF233A66),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start a conversation by contacting a seller from a product listing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF5E6E8C),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.chats.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 80,
                    endIndent: 16,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final chat = controller.chats[index];
                    return _buildChatTile(chat);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatModel chat) {
    final userId = _currentUserId;
    final otherDetails = chat.otherParticipantDetails(userId);
    final otherName = otherDetails?.name ?? 'User';
    final otherPhoto = otherDetails?.photoUrl ?? '';
    final lastMsg = chat.lastMessage;
    final unread = chat.unreadCountFor(userId);
    final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFE8EEF7),
            backgroundImage:
                otherPhoto.isNotEmpty ? NetworkImage(otherPhoto) : null,
            child: otherPhoto.isEmpty
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF233A66),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          if (lastMsg?.timestamp != null)
            Text(
              _formatTimestamp(lastMsg!.timestamp!),
              style: TextStyle(
                color: unread > 0 ? const Color(0xFF233A66) : Colors.grey[400],
                fontSize: 11,
                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (lastMsg?.type == 'image')
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.photo_outlined,
                        size: 14,
                        color: unread > 0
                            ? const Color(0xFF1F2937)
                            : Colors.grey[500],
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _lastMessagePreview(lastMsg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread > 0
                            ? const Color(0xFF1F2937)
                            : Colors.grey[500],
                        fontSize: 13,
                        fontWeight:
                            unread > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF233A66),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.grey[300],
                size: 18,
              ),
          ],
        ),
      ),
      onTap: () {
        Navigator.pushNamed(context, '/chat_detail', arguments: {
          'chatId': chat.id,
          'chat': chat,
        });
      },
    );
  }

  String _lastMessagePreview(LastMessage? lastMessage) {
    if (lastMessage == null) {
      return '';
    }

    if (lastMessage.type == 'image') {
      final previewText = lastMessage.text.trim();
      return previewText.isNotEmpty ? previewText : 'Photo';
    }

    return lastMessage.text;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }
}
