import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 30, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A5F82), AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.5,
                indent: 80,
                endIndent: 16,
                color: Colors.grey.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: AssetImage(message['avatar']),
                      ),
                      if (index == 0) // Just as an example for online status if needed
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Text(
                        message['date'],
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            message['lastMessage'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[300],
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/chat_detail');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _messages = [
    {
      'name': 'Vinayak kadam',
      'lastMessage': 'Hello, is this bike still available.',
      'date': '11/01/2026',
      'avatar': 'assets/images/Oval.png',
    },
    {
      'name': 'Kishori Kale',
      'lastMessage': 'Thank You.',
      'date': '25/12/2025',
      'avatar': 'assets/images/profileimage.png',
    },
    {
      'name': 'Abhi Shinde',
      'lastMessage': 'What is the fix prices',
      'date': '20/12/2025',
      'avatar': 'assets/images/profileimage.png',
    },
    {
      'name': 'Sachin Jathar',
      'lastMessage': 'Photo',
      'date': '11/12/2025',
      'avatar': 'assets/images/profileimage.png',
    },
    {
      'name': 'Amruta Thorat',
      'lastMessage': 'Thank You.',
      'date': '01/12/2025',
      'avatar': 'assets/images/profileimage.png',
    },
    {
      'name': 'Pranav Dumbre',
      'lastMessage': 'Hii good morning',
      'date': '19/11/2025',
      'avatar': 'assets/images/profileimage.png',
    },
    {
      'name': 'Aniket Gadge',
      'lastMessage': 'Hii good morning',
      'date': '11/11/2025',
      'avatar': 'assets/images/profileimage.png',
    },
    {
      'name': 'Aniket Gadge',
      'lastMessage': 'Hii good morning',
      'date': '11/11/2025',
      'avatar': 'assets/images/profileimage.png',
    },
  ];
}
