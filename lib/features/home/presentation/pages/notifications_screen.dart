import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/data/models/app_notification_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.bindNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FBFF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(controller),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refreshNotifications,
                    color: const Color(0xFF233A66),
                    child: _buildContent(controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(NotificationsController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              if (controller.unreadCount > 0)
                TextButton(
                  onPressed: () async {
                    await controller.markAllAsRead();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.unreadCount > 0
                ? '${controller.unreadCount} unread updates'
                : 'All caught up',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(NotificationsController controller) {
    if (controller.isLoading && controller.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(
              color: Color(0xFF233A66),
            ),
          ),
        ],
      );
    }

    if (controller.errorMessage != null && controller.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.notifications_off_outlined,
            size: 56,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load notifications',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF233A66),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await controller.refreshNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF233A66),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    if (controller.notifications.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 62,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF233A66),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Updates about chats, listings, and activity will show up here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      itemCount: controller.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = controller.notifications[index];
        return _buildNotificationItem(
          notification: notification,
          onTap: () => controller.handleNotificationTap(notification),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required AppNotificationModel notification,
    required Future<void> Function() onTap,
  }) {
    final isUnread = !notification.isRead;
    final title = notification.title.trim().isNotEmpty
        ? notification.title.trim()
        : (notification.senderName?.trim().isNotEmpty == true
            ? notification.senderName!.trim()
            : 'Notification');
    final senderName = notification.senderName?.trim() ?? '';
    final shouldShowSenderName = senderName.isNotEmpty &&
        senderName.toLowerCase() != title.toLowerCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFFEFF4FF)
                : const Color(0xFFF1F4F8).withOpacity(0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFFB8CAEE)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(notification),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isUnread
                                  ? const Color(0xFF233A66)
                                  : const Color(0xFF2E3E5C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatRelativeTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E5BFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (shouldShowSenderName) ...[
                      const SizedBox(height: 6),
                      Text(
                        senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5D78),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF5E6E8C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppNotificationModel notification) {
    final senderPhotoUrl = notification.senderPhotoUrl?.trim() ?? '';
    if (senderPhotoUrl.isNotEmpty) {
      return Container(
        height: 48,
        width: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE8EEF7),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            senderPhotoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackAvatar(notification),
          ),
        ),
      );
    }

    return _buildFallbackAvatar(notification);
  }

  Widget _buildFallbackAvatar(AppNotificationModel notification) {
    final senderName = notification.senderName?.trim() ?? '';
    if (senderName.isNotEmpty) {
      final initials = _initialsFromName(senderName);
      return Container(
        height: 48,
        width: 48,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFDCE6F8),
        ),
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF233A66),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      height: 48,
      width: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFE8EEF7),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _iconForType(notification.type),
        color: const Color(0xFF233A66),
        size: 22,
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.trim()) {
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'listing':
      case 'listing_update':
      case 'product_view':
        return Icons.directions_bike_outlined;
      case 'system':
        return Icons.notifications_active_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _initialsFromName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _formatRelativeTime(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes min ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hr ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    final years = (difference.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }
}
