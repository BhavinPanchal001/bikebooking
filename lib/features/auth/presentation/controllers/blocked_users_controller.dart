import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/block_sync_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class BlockedUsersController extends GetxController {
  final SellerActionFirestoreService _sellerActionService =
      SellerActionFirestoreService();
  final LoginController _loginController = Get.find<LoginController>();

  bool isLoading = false;
  List<Map<String, dynamic>> blockedUsers = [];
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    loadBlockedUsers();
  }

  Future<void> loadBlockedUsers() async {
    final currentUserId = _loginController.resolvedCurrentUserId.trim();
    if (currentUserId.isEmpty) return;
    final currentUser = _loginController.currentUserProfile;

    isLoading = true;
    errorMessage = null;
    update();

    try {
      final selfIdentifiers = <String>{
        currentUserId.toLowerCase(),
        (currentUser?.displayName.trim().toLowerCase() ?? ''),
        (currentUser?.phoneNumber.trim().toLowerCase() ?? ''),
        (currentUser?.registeredMobileNumber.trim().toLowerCase() ?? ''),
      }..removeWhere((value) => value.isEmpty);

      blockedUsers =
          (await _sellerActionService.getBlockedSellers(currentUserId))
              .where((blockedUser) {
        final blockedUserId =
            blockedUser['blockedUserId']?.toString().trim().toLowerCase() ?? '';
        final fullName =
            blockedUser['fullName']?.toString().trim().toLowerCase() ?? '';
        final sellerName =
            blockedUser['sellerName']?.toString().trim().toLowerCase() ?? '';

        return !selfIdentifiers.contains(blockedUserId) &&
            !selfIdentifiers.contains(fullName) &&
            !selfIdentifiers.contains(sellerName);
      }).toList(growable: false);
    } catch (e) {
      errorMessage = 'Failed to load blocked users.';
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<bool> unblockUser(String blockedUserId) async {
    final currentUserId = _loginController.resolvedCurrentUserId.trim();
    final normalizedBlockedUserId = blockedUserId.trim();
    if (currentUserId.isEmpty || normalizedBlockedUserId.isEmpty) {
      return false;
    }

    try {
      await _sellerActionService.unblockSeller(
        userId: currentUserId,
        sellerId: normalizedBlockedUserId,
      );
    } catch (error, stackTrace) {
      debugPrint('Error unblocking user: $error\n$stackTrace');
    }

    await loadBlockedUsers();

    final isStillBlocked = blockedUsers.any(
      (user) =>
          user['blockedUserId']?.toString().trim() == normalizedBlockedUserId,
    );
    if (isStillBlocked) {
      return false;
    }

    _refreshDependentControllers();
    return true;
  }

  void _refreshDependentControllers() {
    try {
      BlockSyncHelper.refreshAfterBlockChange();
    } catch (error, stackTrace) {
      debugPrint(
        'Error refreshing dependent controllers after unblock: '
        '$error\n$stackTrace',
      );
    }
  }
}
