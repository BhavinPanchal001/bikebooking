import 'package:flutter/material.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello, is this bike still available.', 'isMe': false, 'time': '12:15'},
    {'text': 'Yes, it\'s still available. Let me know if you have any questions.', 'isMe': true, 'time': '12:15'},
    {'text': 'Great, can i take a look at the bike today ?', 'isMe': false, 'time': '12:15'},
    {'text': 'Sure, what time would be convenient for you?', 'isMe': true, 'time': '12:15'},
    {'text': 'How about at 4pm ?', 'isMe': false, 'time': '12:15'},
    {'text': 'ok', 'isMe': true, 'time': '12:15'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E3E5C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/profile_pic.png'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Vinayak kadam',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16),
                        ],
                      ),
                      Text(
                        'Last seen 1 minute ago',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportBottomSheet(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'block', child: Text('Block user')),
                    const PopupMenuItem(value: 'report', child: Text('Report user')),
                  ],
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Today',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
                ..._messages.map((msg) => _buildMessageBubble(msg['text'], msg['isMe'], msg['time'])),
              ],
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F8),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Write your message here',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 54,
                  width: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E3E5C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF2E3E5C) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
            boxShadow: [
              if (!isMe)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : const Color(0xFF2E3E5C),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe) ...[
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.done_all, color: Color(0xFF4A6CAD), size: 14),
            ] else ...[
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.done_all, color: Color(0xFF4A6CAD), size: 14),
            ],
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ReportBottomSheet(),
    );
  }
}

class _ReportBottomSheet extends StatefulWidget {
  const _ReportBottomSheet();

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();

  final List<String> _reasons = [
    'Inappropriate picture',
    'This user is insulting me',
    'Spam',
    'Fraud',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Report User',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((reason) => _buildReasonItem(reason)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CAD),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          // Spacer for keyboard
          Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
        ],
      ),
    );
  }

  Widget _buildReasonItem(String reason) {
    bool isSelected = _selectedReason == reason;
    bool isOther = reason == 'Other';

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedReason = reason),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? const Color(0xFF2E3E5C) : Colors.grey.shade400, width: 2),
                      ),
                      child: isSelected
                          ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2E3E5C), shape: BoxShape.circle)))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(reason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2E3E5C))),
                  ],
                ),
                if (isOther && isSelected) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otherReasonController,
                    decoration: InputDecoration(
                      hintText: 'Please describe the issue...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
