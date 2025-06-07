// lib/models/chat_message.dart

class ChatMessage {
  final String id;
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });
}
