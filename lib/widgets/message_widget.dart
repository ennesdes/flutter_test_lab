import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'text_message_widget.dart';
import 'audio_message_widget.dart';

class MessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isUserMessage;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isUserMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = isUserMessage;
    
    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 50 : 8,
        right: isUser ? 8 : 50,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Conteúdo da mensagem baseado no tipo
          _buildMessageContent(),
          
          const SizedBox(height: 4),
          
          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 8,
              right: isUser ? 8 : 0,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return TextMessageWidget(
          message: message,
          isUserMessage: isUserMessage,
        );
      case MessageType.audio:
        return AudioMessageWidget(
          message: message,
          isUserMessage: isUserMessage,
        );
      case MessageType.image:
        // TODO: Implementar widget de imagem
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Imagem (não implementada)'),
        );
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ontem ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

