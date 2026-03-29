import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/auth/presentation/controllers/blocked_users_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late final BlockedUsersController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BlockedUsersController>()) {
      _controller = Get.find<BlockedUsersController>();
      _ownsController = false;
    } else {
      _controller = Get.put(BlockedUsersController());
      _ownsController = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadBlockedUsers();
    });
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<BlockedUsersController>()) {
      Get.delete<BlockedUsersController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Blocked Users',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<BlockedUsersController>(
                builder: (controller) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.errorMessage!,
                            style: const TextStyle(color: Color(0xFF2E3E5C)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: controller.loadBlockedUsers,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.blockedUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No blocked users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3E5C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Users you block will appear here.',
                            style: TextStyle(color: Color(0xFF5E6E8C)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.blockedUsers.length,
                    itemBuilder: (context, index) {
                      final blockedUser = controller.blockedUsers[index];
                      return _buildBlockedUserCard(
                        context,
                        controller,
                        blockedUser,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUserCard(
    BuildContext context,
    BlockedUsersController controller,
    Map<String, dynamic> blockedUser,
  ) {
    final photoUrl = blockedUser['photoUrl']?.toString() ?? '';
    final fullName =
        (blockedUser['fullName']?.toString().trim().isNotEmpty == true
                ? blockedUser['fullName'].toString().trim()
                : blockedUser['sellerName']?.toString().trim()) ??
            'User';
    final blockedUserId = blockedUser['blockedUserId'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          photoUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(photoUrl),
                )
              : CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFEAF0FB),
                  child: Text(
                    fullName.isNotEmpty
                        ? fullName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF233A66),
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2E3E5C),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showUnblockConfirmation(
              context,
              controller,
              fullName,
              blockedUserId,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirmation(
    BuildContext context,
    BlockedUsersController controller,
    String userName,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.unblockUser(userId);
              if (success) {
                Get.snackbar(
                  'Success',
                  '$userName has been unblocked',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to unblock $userName',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Unblock', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
