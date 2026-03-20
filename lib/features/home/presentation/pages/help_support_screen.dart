import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
                    'Help & Support',
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
                  _buildSectionTitle('Introduction'),
                  const Text(
                    'Welcome to Bike Nest Help Center. We are here to assist you with any questions or issues related to your account, ads, payments, and safety. Please check the frequently asked questions below. If your issue is not resolved, you can contact our support team directly from the app',
                    style: TextStyle(color: Color(0xFF5E6E8C), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('My Account'),
                  _buildFaqItem('How do I update my profile information on Bike Nest?'),
                  _buildFaqItem('How can I change my registered mobile number or email address?'),
                  _buildFaqItem('Why is my account suspended?'),
                  _buildFaqItem('How do I delete my Bike Nest account?'),
                  _buildFaqItem('How do I update my profile information on Bike Nest?'),
                  _buildFaqItem('How can I change my registered mobile number or email address?'),
                  _buildFaqItem('Why is my account suspended?'),
                  _buildFaqItem('How do I delete my Bike Nest account?'),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Posting & Managing Ads'),
                  _buildFaqItem('How do I post an ad on Bike Nest?'),
                  _buildFaqItem('How can I edit my posted ad?'),
                  _buildFaqItem('How do I delete my ad from Bike Nest?'),
                  _buildFaqItem('How can I mark my ad as sold?'),
                  _buildFaqItem('Why was my ad rejected or removed?'),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Application Related Issues'),
                  _buildFaqItem('Why is the Bike Nest app not opening properly?'),
                  _buildFaqItem('Why is the app running slow?'),
                  _buildFaqItem('Why am I not receiving notifications from Bike Nest?'),
                  _buildFaqItem('How can I mark my ad as sold?'),
                  _buildFaqItem('What should I do if the app shows an error message?'),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Safety & Security'), // In screenshot it says 'Application Related Issues' again but content looks safety related
                  _buildFaqItem('How can I identify a fake or suspicious listing?'),
                  _buildFaqItem('Is it safe to make payments outside Bike Nest?'),
                  _buildFaqItem('What should I do if someone asks for advance payment?'),
                  _buildFaqItem('How can I report fraud or suspicious activity?'),
                  _buildFaqItem('How can I stay safe while meeting a buyer or seller?'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E3E5C),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF5E6E8C),
          height: 1.4,
        ),
      ),
    );
  }
}
