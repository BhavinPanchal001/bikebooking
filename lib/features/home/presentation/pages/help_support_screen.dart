import 'package:bikebooking/features/home/presentation/pages/cms_page_screen.dart';
import 'package:flutter/material.dart';

const String _helpSupportFallbackMarkdown = '''
# Help & Support

Welcome to the Bike Nest Help Center. We are here to assist you with questions about your account, ads, payments, and safety.

## My Account

- How do I update my profile information on Bike Nest?
- How can I change my registered mobile number or email address?
- Why is my account suspended?
- How do I delete my Bike Nest account?

## Posting & Managing Ads

- How do I post an ad on Bike Nest?
- How can I edit my posted ad?
- How do I delete my ad from Bike Nest?
- How can I mark my ad as sold?
- Why was my ad rejected or removed?

## Application Related Issues

- Why is the Bike Nest app not opening properly?
- Why is the app running slow?
- Why am I not receiving notifications from Bike Nest?
- What should I do if the app shows an error message?

## Safety & Security

- How can I identify a fake or suspicious listing?
- Is it safe to make payments outside Bike Nest?
- What should I do if someone asks for advance payment?
- How can I report fraud or suspicious activity?
- How can I stay safe while meeting a buyer or seller?

## Need More Help?

If your issue is still unresolved, contact **support@bikenest.com** and include the details of your account, listing, or payment issue.
''';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPageScreen(
      slug: 'help-support',
      fallbackTitle: 'Help & Support',
      fallbackMarkdown: _helpSupportFallbackMarkdown,
    );
  }
}
