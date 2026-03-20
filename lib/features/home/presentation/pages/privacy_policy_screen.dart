import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
              decoration: const BoxDecoration(
                color: Color(0xFF233A66),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
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
                    'Privacy Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'At Bike Nest, we value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, store, and protect your information when you use our application.\nBy using Bike Nest, you agree to the collection and use of information in accordance with this Privacy Policy.',
                    style: TextStyle(color: Color(0xFF5E6E8C), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  _buildSection('Information We Collect', 
                    'When you create an account on Bike Nest, we may collect personal information such as your name, mobile number, email address, profile details, and location. We may also collect information related to your listings, messages, transactions, and activity within the app.\nIn addition, we may automatically collect certain technical information such as device type, operating system, IP address, and usage data to improve the performance and security of the application.'),
                  
                  _buildSection('How We Use Your Information', 
                    'Bike Nest uses your information to create and manage your account, enable buying and selling activities, process payments and subscriptions, improve user experience, provide customer support, and ensure platform safety.\nWe may also use your contact details to send important notifications, updates, promotional offers, or service-related messages.'),
                  
                  _buildSection('Sharing of Information', 
                    'Bike Nest does not sell your personal information to third parties. We may share your information with trusted service providers who help us operate the platform, process payments, or provide technical support. These third parties are required to protect your information and use it only for authorized purposes.\nWe may also disclose information if required by law or to protect the rights, safety, and security of Bike Nest and its users.'),
                  
                  _buildSection('Data Security', 
                    'We take appropriate security measures to protect your personal information from unauthorized access, misuse, or disclosure. However, no online platform can guarantee complete security, and users are encouraged to keep their login credentials confidential.'),
                  
                  _buildSection('User Rights', 
                    'You have the right to access, update, or delete your personal information through your account settings. If you wish to delete your account, you may do so from the settings section or contact our support team for assistance.'),
                  
                  _buildSection('Contact Us', 
                    'If you have any questions regarding this Privacy Policy, you can contact us at:\nEmail: support@bikenest.com'),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3E5C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF5E6E8C),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
