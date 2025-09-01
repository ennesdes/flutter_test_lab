import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'audio_input_widget.dart';
import 'mobile_audio_input_widget.dart';
import '../audio/services/audio_service_factory.dart';


class ChatInputWidget extends StatefulWidget {
  final Function(ChatMessage) onMessageSent;
  final Function(ChatMessage) onAudioMessageSent;

  const ChatInputWidget({
    super.key,
    required this.onMessageSent,
    required this.onAudioMessageSent,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Estados da interface
  bool _isRecordingMode = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ============================================================================
  // CONTROLE DE MENSAGENS
  // ============================================================================
  
  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        type: MessageType.text,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );
      widget.onMessageSent(message);
      _textController.clear();
    }
  }

  void _handleAudioMessageSent(ChatMessage audioMessage) {
    widget.onAudioMessageSent(audioMessage);
    setState(() {
      _isRecordingMode = false;
    });
  }

  void _cancelAudioRecording() {
    setState(() {
      _isRecordingMode = false;
    });
  }

  void _startAudioRecording() {
    setState(() {
      _isRecordingMode = true;
    });
  }

  // ============================================================================
  // WIDGETS DE INTERFACE
  // ============================================================================
  
  Widget _buildAudioInput() {
    if (AudioServiceFactory.isMobile()) {
      return MobileAudioInputWidget(
        onAudioMessageSent: _handleAudioMessageSent,
        onCancel: _cancelAudioRecording,
        useCompactInterface: false, // Pode ser configurável
      );
    } else {
      return AudioInputWidget(
        onAudioMessageSent: _handleAudioMessageSent,
        onCancel: _cancelAudioRecording,
      );
    }
  }
  
  Widget _buildTextInput() {
    return Row(
      children: [
        // Botão de anexos
        IconButton(
          onPressed: () {
            // TODO: Implementar anexos
          },
          icon: const Icon(Icons.add),
          color: Colors.grey[600],
        ),
        
        // Campo de texto
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Digite aqui sua mensagem.',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Botão de câmera
        IconButton(
          onPressed: () {
            // TODO: Implementar câmera
          },
          icon: const Icon(Icons.camera_alt),
          color: Colors.grey[600],
        ),
        
        const SizedBox(width: 8),
        
        // Botão de gravação ou envio
        GestureDetector(
          onTap: _textController.text.trim().isNotEmpty 
              ? _sendTextMessage 
              : _startAudioRecording,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _textController.text.trim().isNotEmpty 
                  ? Icons.send 
                  : Icons.mic,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: _isRecordingMode 
            ? _buildAudioInput()
            : _buildTextInput(),
      ),
    );
  }
}


