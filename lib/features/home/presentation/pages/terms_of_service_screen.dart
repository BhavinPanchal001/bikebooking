import 'package:bikebooking/features/home/presentation/pages/cms_page_screen.dart';
import 'package:flutter/material.dart';

const String _termsOfServiceFallbackMarkdown = '''
# Terms of Service

Welcome to Bikebooking. By using the app, you agree to follow these terms while buying, selling, messaging, or managing listings on the platform.

## Eligibility

- You must provide accurate account details and keep your login credentials secure.
- You are responsible for all activity carried out through your account.

## Listings and Content

- Listings must be genuine, lawful, and accurately describe the bike, spare part, or accessory being offered.
- Do not post misleading pricing, copied photos, or duplicate listings intended to manipulate visibility.
- Bikebooking may remove or restrict any listing that violates platform rules or local law.

## Payments and Promotions

- Promotional plans, boosts, and any system fees shown in the app must be paid through approved payment flows.
- Completed purchases are subject to the plan or fee details displayed at checkout.

## Marketplace Safety

- Communicate respectfully with buyers and sellers.
- Do not request advance payments outside trusted flows unless both parties clearly agree and understand the risk.
- Report suspicious activity, abusive behavior, or fraudulent listings through the app.

## Account Actions

- Bikebooking may suspend, limit, or remove accounts involved in fraud, abuse, impersonation, or repeated policy violations.
- You may request account deletion according to the support and privacy instructions available in the app.

## Contact

For help with these terms, contact **support@bikenest.com**.
''';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPageScreen(
      slug: 'terms-of-service',
      fallbackTitle: 'Terms of Service',
      fallbackMarkdown: _termsOfServiceFallbackMarkdown,
    );
  }
}
