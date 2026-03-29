import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/chat/data/models/message_model.dart';
import 'package:bikebooking/features/chat/presentation/controllers/chat_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  // ignore: unused_field
  late final ChatDetailController _controller;
  String? _chatId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chatId != null) return; // Already initialized.

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _chatId = args?['chatId']?.toString() ?? '';

    if (_chatId!.isEmpty) return;

    if (Get.isRegistered<ChatDetailController>(tag: _chatId)) {
      _controller = Get.find<ChatDetailController>(tag: _chatId);
    } else {
      _controller = Get.put(
        ChatDetailController(chatId: _chatId!),
        tag: _chatId,
      );
    }
  }

  @override
  void dispose() {
    if (_chatId != null &&
        _chatId!.isNotEmpty &&
        Get.isRegistered<ChatDetailController>(tag: _chatId)) {
      Get.delete<ChatDetailController>(tag: _chatId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null || _chatId!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FBFF),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Invalid conversation.',
                  style: TextStyle(color: Color(0xFF5E6E8C))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: GetBuilder<ChatDetailController>(
        tag: _chatId,
        builder: (controller) {
          return Column(
            children: [
              // Header
              _buildHeader(controller),

              // Product Info (if chat is about a product)
              if (controller.productSnapshot != null)
                _buildProductBanner(controller),

              // Message List
              Expanded(
                child: controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF233A66),
                        ),
                      )
                    : controller.errorMessage != null
                        ? Center(
                            child: Text(
                              controller.errorMessage!,
                              style: const TextStyle(color: Color(0xFF5E6E8C)),
                            ),
                          )
                        : controller.messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet. Say hello!',
                                  style: TextStyle(color: Color(0xFF5E6E8C)),
                                ),
                              )
                            : ListView.builder(
                                controller: controller.scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  8,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: controller.messages.length,
                                itemBuilder: (context, index) {
                                  final message = controller.messages[index];
                                  final isMe = controller.isMyMessage(message);

                                  // Show date separator.
                                  final showDateSeparator =
                                      _shouldShowDateSeparator(
                                    controller.messages,
                                    index,
                                  );

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (showDateSeparator)
                                        _buildDateSeparator(message),
                                      _buildMessageBubble(
                                        message,
                                        isMe,
                                        controller,
                                      ),
                                    ],
                                  );
                                },
                              ),
              ),

              if (controller.canComposeMessages)
                _buildMessageInput(controller)
              else if (!controller.isLoading && controller.isChatBlocked)
                _buildLockedConversationNotice(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ChatDetailController controller) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert, color: Colors.white, size: 28),
                onSelected: (value) {
                  if (value == 'block') {
                    _showBlockUserDialog(context, controller);
                  }
                  if (value == 'report') {
                    _showReportBottomSheet(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'block',
                    child: Text(
                      controller.isOtherUserBlockedByCurrentUser
                          ? 'Unblock user'
                          : 'Block user',
                    ),
                  ),
                  const PopupMenuItem(
                      value: 'report', child: Text('Report user')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFFE8EEF7),
                    backgroundImage: controller.otherUserPhoto.isNotEmpty
                        ? NetworkImage(controller.otherUserPhoto)
                        : null,
                    child: controller.otherUserPhoto.isEmpty
                        ? Text(
                            controller.otherUserName.isNotEmpty
                                ? controller.otherUserName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Color(0xFF233A66),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  if (controller.isOtherUserOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.otherUserName.isNotEmpty
                                ? controller.otherUserName
                                : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (controller.isOtherUserOnline)
                          const Icon(Icons.check_circle,
                              color: Color(0xFF4ADE80), size: 18),
                      ],
                    ),
                    if (controller.lastSeenText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          controller.lastSeenText,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductBanner(ChatDetailController controller) {
    final product = controller.productSnapshot!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 40,
              color: const Color(0xFFF1F4F8),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                          Icons.directions_bike,
                          size: 20,
                          color: Colors.grey))
                  : const Icon(Icons.directions_bike,
                      size: 20, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E3E5C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.price != null)
                  Text(
                    'Rs.${product.price!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF233A66),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].timestamp;
    final previous = messages[index - 1].timestamp;
    if (current == null || previous == null) return false;
    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  Widget _buildDateSeparator(MessageModel message) {
    final timestamp = message.timestamp;
    String label;

    if (timestamp == null) {
      label = '';
    } else {
      final now = DateTime.now();
      final diff = now.difference(timestamp);
      if (diff.inDays == 0) {
        label = 'Today';
      } else if (diff.inDays == 1) {
        label = 'Yesterday';
      } else {
        label = DateFormat('dd MMM yyyy').format(timestamp);
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8D96A8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isMe,
    ChatDetailController controller,
  ) {
    final currentUserId = Get.find<LoginController>().chatUserId;
    final timestamp = message.timestamp;
    final timeStr =
        timestamp != null ? DateFormat('HH:mm').format(timestamp) : '';
    final isRead = !isMe ||
        (controller.chat != null &&
            message.isReadBy(
              controller.chat!.otherParticipantId(
                currentUserId,
              ),
            ));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF2F497E) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    if (!isMe)
                      BoxShadow(
                        color: const Color(0xFF233A66).withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF263238),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Color(0xFF5E74A6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    color: isRead
                        ? const Color(0xFF38599A)
                        : const Color(0xFF9AA7C1),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatDetailController controller) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE0E7F2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: controller.messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => controller.sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Write your message here',
                    hintStyle: TextStyle(
                      color: Color(0xFF9AA3B5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => controller.sendMessage(),
              child: Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF2F497E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedConversationNotice(ChatDetailController controller) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E7F2)),
        ),
        child: Text(
          controller.errorMessage ??
              'This conversation is unavailable because one of you has blocked the other.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5E6E8C),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void _showBlockUserDialog(
    BuildContext context,
    ChatDetailController controller,
  ) {
    final isUnblock = controller.isOtherUserBlockedByCurrentUser;
    final userName = controller.otherUserName.isNotEmpty
        ? controller.otherUserName
        : 'this user';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isUnblock ? 'Unblock User' : 'Block User'),
        content: Text(
          isUnblock
              ? 'Do you want to unblock $userName?'
              : 'If you block $userName, they will no longer be able to chat with you or see your listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await controller.toggleBlockOtherUser();
              if (!context.mounted) {
                return;
              }

              if (success) {
                Get.snackbar(
                  isUnblock ? 'User unblocked' : 'User blocked',
                  isUnblock
                      ? '$userName can chat with you again.'
                      : '$userName has been blocked successfully.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Error',
                  isUnblock
                      ? 'Unable to unblock $userName right now.'
                      : 'Unable to block $userName right now.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text(isUnblock ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ReportBottomSheet(),
    );
  }
}

class _ReportBottomSheet extends StatefulWidget {
  const _ReportBottomSheet();

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();

  final List<String> _reasons = [
    'Inappropriate picture',
    'This user is insulting me',
    'Spam',
    'Fraud',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Report User',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3E5C)),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((reason) => _buildReasonItem(reason)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CustomGradientButton(
              text: 'Submit',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Report submitted successfully',
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom)),
        ],
      ),
    );
  }

  Widget _buildReasonItem(String reason) {
    bool isSelected = _selectedReason == reason;
    bool isOther = reason == 'Other';

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedReason = reason),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2E3E5C)
                                : Colors.grey.shade400,
                            width: 2),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF2E3E5C),
                                      shape: BoxShape.circle)))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(reason,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2E3E5C))),
                  ],
                ),
                if (isOther && isSelected) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otherReasonController,
                    decoration: InputDecoration(
                      hintText: 'Please describe the issue...',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
