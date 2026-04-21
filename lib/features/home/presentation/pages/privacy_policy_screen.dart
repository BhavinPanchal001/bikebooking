import 'package:bikebooking/features/home/presentation/pages/cms_page_screen.dart';
import 'package:flutter/material.dart';

const String _privacyPolicyFallbackMarkdown = '''
# Privacy Policy

At Bike Nest, we value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, store, and protect your information when you use our application.

By using Bike Nest, you agree to the collection and use of information in accordance with this Privacy Policy.

## Information We Collect

When you create an account on Bike Nest, we may collect personal information such as your name, mobile number, email address, profile details, and location. We may also collect information related to your listings, messages, transactions, and activity within the app.

In addition, we may automatically collect technical information such as device type, operating system, IP address, and usage data to improve app performance and security.

## How We Use Your Information

Bike Nest uses your information to create and manage your account, enable buying and selling activities, process payments and subscriptions, improve user experience, provide customer support, and keep the platform safe.

We may also use your contact details to send important notifications, updates, promotional offers, or service-related messages.

## Sharing of Information

Bike Nest does not sell your personal information to third parties. We may share your information with trusted service providers who help us operate the platform, process payments, or provide technical support. These partners are required to protect your information and use it only for authorized purposes.

We may also disclose information if required by law or to protect the rights, safety, and security of Bike Nest and its users.

## Data Security

We take appropriate security measures to protect your personal information from unauthorized access, misuse, or disclosure. No online platform can guarantee complete security, so users should keep their login credentials confidential.

## User Rights

You can access, update, or delete your personal information through your account settings. If you want to delete your account, use the settings section or contact support for help.

## Contact Us

If you have any questions regarding this Privacy Policy, contact **support@bikenest.com**.
''';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPageScreen(
      slug: 'privacy-policy',
      fallbackTitle: 'Privacy Policy',
      fallbackMarkdown: _privacyPolicyFallbackMarkdown,
    );
  }
}
