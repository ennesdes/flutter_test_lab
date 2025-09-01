import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/providers/audio_provider.dart';
import '../audio/models/audio_state.dart';
import '../models/chat_message.dart';

class AudioInputWidget extends StatefulWidget {
  final Function(ChatMessage) onAudioMessageSent;
  final VoidCallback onCancel;

  const AudioInputWidget({
    super.key,
    required this.onAudioMessageSent,
    required this.onCancel,
  });

  @override
  State<AudioInputWidget> createState() => _AudioInputWidgetState();
}

class _AudioInputWidgetState extends State<AudioInputWidget> {
  @override
  void initState() {
    super.initState();
    // Iniciar gravação automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().startRecording(maxDuration: const Duration(minutes: 3));
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _handleSendAudio() async {
    final audioProvider = context.read<AudioProvider>();
    final audioPath = await audioProvider.stopRecording();
    
    if (audioPath != null) {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Mensagem de áudio',
        type: MessageType.audio,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        audioPath: audioPath,
        audioDuration: audioProvider.currentState.recordDuration,
      );
      widget.onAudioMessageSent(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final state = audioProvider.currentState;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de gravação
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gravando...',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                                Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(state.recordDuration),
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Barra de progresso do limite de tempo
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: state.maxRecordDuration.inMilliseconds > 0
                          ? (state.recordDuration.inMilliseconds / state.maxRecordDuration.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: state.recordDuration.inMilliseconds > state.maxRecordDuration.inMilliseconds * 0.8
                              ? Colors.orange
                              : Colors.red[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Controles de gravação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botão de cancelar
                  GestureDetector(
                    onTap: () async {
                      await audioProvider.stopRecording();
                      widget.onCancel();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Botão de pausar/retomar
                  if (state.recordingState == AudioRecordingState.recording)
                    GestureDetector(
                      onTap: () => audioProvider.pauseRecording(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.orange[400],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    )
                  else if (state.recordingState == AudioRecordingState.paused)
                    GestureDetector(
                      onTap: () => audioProvider.resumeRecording(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  
                  // Botão de enviar
                  GestureDetector(
                    onTap: _handleSendAudio,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Texto de instrução
              Text(
                state.recordingState == AudioRecordingState.paused
                    ? 'Gravação pausada - Toque para continuar'
                    : 'Toque para pausar ou enviar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

