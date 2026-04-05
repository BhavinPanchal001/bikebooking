import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/data/models/notification_preferences_model.dart';
import 'package:bikebooking/features/home/data/services/notification_push_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({super.key});

  @override
  State<ManageNotificationsScreen> createState() =>
      _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState extends State<ManageNotificationsScreen> {
  late final NotificationPushService _notificationPushService;

  @override
  void initState() {
    super.initState();
    _notificationPushService = Get.find<NotificationPushService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationPushService.refreshPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationPushService>(
      builder: (notificationService) {
        final preferences = notificationService.preferences;
        final isBusy = notificationService.isLoadingPreferences ||
            notificationService.isUpdatingPreferences;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBFF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: notificationService.isLoadingPreferences &&
                          !notificationService.hasSignedInUser
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildStatusCard(notificationService),
                            const SizedBox(height: 20),
                            if (!notificationService.hasSignedInUser)
                              _buildInfoCard(
                                title: 'Sign in to manage notifications',
                                description:
                                    'Notification preferences are saved against your account after you sign in.',
                              )
                            else ...[
                              _buildSectionHeader('General Notifications'),
                              _buildSwitchTile(
                                'All Notifications',
                                'Turn Bikebooking push notifications on or off for this device.',
                                preferences.allNotifications,
                                isBusy,
                                (value) => _savePreferences(
                                  preferences.copyWith(allNotifications: value),
                                  requestPermissionOnEnable: value,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionHeader('Ad & Listing Notifications'),
                              _buildSwitchTile(
                                'Ad & Listing Notifications',
                                'Updates about your listings and ad activity.',
                                preferences.adListing,
                                isBusy || !preferences.allNotifications,
                                (value) => _savePreferences(
                                  preferences.copyWith(adListing: value),
                                ),
                              ),
                              _buildDivider(),
                              _buildSwitchTile(
                                'New Message on My Ad',
                                'Alert me when someone starts or replies to a chat.',
                                preferences.newMessage,
                                isBusy || !preferences.allNotifications,
                                (value) => _savePreferences(
                                  preferences.copyWith(newMessage: value),
                                ),
                              ),
                              _buildDivider(),
                              _buildSwitchTile(
                                'Someone Viewed My Ad',
                                'Track new view activity on my listing.',
                                preferences.viewedAd,
                                isBusy || !preferences.allNotifications,
                                (value) => _savePreferences(
                                  preferences.copyWith(viewedAd: value),
                                ),
                              ),
                              _buildDivider(),
                              _buildSwitchTile(
                                'Ad Expiring Soon',
                                'Remind me before a listing expires.',
                                preferences.expiringSoon,
                                isBusy || !preferences.allNotifications,
                                (value) => _savePreferences(
                                  preferences.copyWith(expiringSoon: value),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionHeader('Payment & Subscription'),
                              _buildSwitchTile(
                                'Payment Failed',
                                'Important account and billing updates.',
                                preferences.paymentFailed,
                                isBusy || !preferences.allNotifications,
                                (value) => _savePreferences(
                                  preferences.copyWith(paymentFailed: value),
                                ),
                              ),
                              _buildDivider(),
                              _buildSwitchTile(
                                'Subscription Expiring Reminder',
                                'Stay ahead of subscription renewals.',
                                preferences.subscriptionReminder,
                                isBusy || !preferences.allNotifications,
                                (value) => _savePreferences(
                                  preferences.copyWith(
                                    subscriptionReminder: value,
                                  ),
                                ),
                              ),
                              if (notificationService.preferencesErrorMessage !=
                                  null) ...[
                                const SizedBox(height: 16),
                                _buildInfoCard(
                                  title: 'Update issue',
                                  description: notificationService
                                      .preferencesErrorMessage!,
                                  isWarning: true,
                                ),
                              ],
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePreferences(
    NotificationPreferencesModel preferences, {
    bool requestPermissionOnEnable = false,
  }) async {
    await _notificationPushService.updatePreferences(
      preferences,
      requestPermissionOnEnable: requestPermissionOnEnable,
    );
  }

  Widget _buildHeader() {
    return Container(
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
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Manage Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(NotificationPushService notificationService) {
    final isPermissionEnabled = notificationService.isDevicePermissionEnabled;
    final isPushEnabled = notificationService.isNotificationsEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: isPushEnabled
                      ? const Color(0xFFE5F3EA)
                      : const Color(0xFFFFF2E7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPushEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: isPushEnabled
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFDD6B20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPushEnabled
                      ? 'Push notifications are active'
                      : 'Push notifications need attention',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF233A66),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notificationService.permissionStatusDescription,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF5E6E8C),
            ),
          ),
          if (!isPermissionEnabled && notificationService.hasSignedInUser) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: notificationService.isUpdatingPreferences
                    ? null
                    : notificationService.requestDevicePermission,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF233A66),
                  side: const BorderSide(color: Color(0xFFB8CAEE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Request Notification Access'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning
            ? const Color(0xFFFFF6EC)
            : const Color(0xFFF1F4F8).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFFFD8AE)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF233A66),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF5E6E8C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8).withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5E6E8C),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    bool isDisabled,
    ValueChanged<bool> onChanged,
  ) {
    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Colors.black.withOpacity(0.05)),
            right: BorderSide(color: Colors.black.withOpacity(0.05)),
            bottom: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF6C7B96),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Transform.scale(
              scale: 0.78,
              child: Switch(
                value: value,
                onChanged: isDisabled ? null : onChanged,
                activeColor: const Color(0xFF4CAF50),
                activeTrackColor: const Color(0xFFC8E6C9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      color: Colors.white,
      child: Divider(
        height: 1,
        color: Colors.grey.shade100,
        indent: 16,
        endIndent: 16,
      ),
    );
  }
}
