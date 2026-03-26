import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({super.key});

  @override
  State<ManageNotificationsScreen> createState() => _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState extends State<ManageNotificationsScreen> {
  bool allNotifications = true;
  bool adListing = true;
  bool newMessage = true;
  bool viewedAd = true;
  bool expiringSoon = true;
  bool paymentFailed = true;
  bool subscriptionReminder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // General Section
                  _buildSectionHeader('General Notifications'),
                  _buildSwitchTile('All Notifications', allNotifications, (v) => setState(() => allNotifications = v)),
                  const SizedBox(height: 24),

                  // Ad & Listing Section
                  _buildSectionHeader('Ad & Listing Notifications'),
                  _buildSwitchTile('Ad & Listing Notifications', adListing, (v) => setState(() => adListing = v)),
                  _buildDivider(),
                  _buildSwitchTile('New Message on My Ad', newMessage, (v) => setState(() => newMessage = v)),
                  _buildDivider(),
                  _buildSwitchTile('Some Viewed My Ad', viewedAd, (v) => setState(() => viewedAd = v)),
                  _buildDivider(),
                  _buildSwitchTile('Ad Expiring Soon', expiringSoon, (v) => setState(() => expiringSoon = v)),
                  const SizedBox(height: 24),

                  // Payment Section
                  _buildSectionHeader('Payment & Subscription'),
                  _buildSwitchTile('Payment Failed', paymentFailed, (v) => setState(() => paymentFailed = v)),
                  _buildDivider(),
                  _buildSwitchTile('Subscription Expiring Reminder', subscriptionReminder,
                      (v) => setState(() => subscriptionReminder = v)),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.black.withOpacity(0.05)),
          right: BorderSide(color: Colors.black.withOpacity(0.05)),
          bottom: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E3E5C),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF4CAF50),
              activeTrackColor: const Color(0xFFC8E6C9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
        color: Colors.white, child: Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16));
  }
}
