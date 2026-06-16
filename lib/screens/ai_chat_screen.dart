import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I\'m your AI health assistant. How can I help you today?',
      isUser: false,
      time: '10:00 AM',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        time: _getCurrentTime(),
      ));
      _messageController.clear();
    });

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _getAIResponse(userMessage),
            isUser: false,
            time: _getCurrentTime(),
          ));
        });
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _getAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    if (message.contains('hello') || message.contains('hi')) {
      return 'Hello there! I\'m here to help you manage your health data. What\'s on your mind?';
    } else if (message.contains('heart') || message.contains('bp')) {
      return 'I see you\'re asking about cardiovascular health. Based on your recent logs, your heart rate has been stable. Would you like me to show your weekly heart rate trends?';
    } else {
      return 'I understand. I\'m analyzing your health profile and the latest medical guidelines to provide you with the best insights. Remember, I\'m an AI assistant, and you should always consult with your doctor for serious concerns.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkMeshGradient : AppColors.primaryGradient,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health AI',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Assistant Active',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.attachment_rounded, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your health query...',
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.textLight.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  margin: const EdgeInsets.only(right: 12, bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 290),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppColors.primaryGradient : null,
                    color: isUser ? null : (isDark ? theme.cardTheme.color : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(28),
                      topRight: const Radius.circular(28),
                      bottomLeft: Radius.circular(isUser ? 28 : 8),
                      bottomRight: Radius.circular(isUser ? 8 : 28),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 56,
              right: isUser ? 12 : 0,
            ),
            child: Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textLight.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
