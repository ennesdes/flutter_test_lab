import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/providers/audio_provider.dart';
import '../audio/models/audio_state.dart';
import '../models/chat_message.dart';
import '../audio/services/audio_service_factory.dart';

class MobileAudioInputWidget extends StatefulWidget {
  final Function(ChatMessage) onAudioMessageSent;
  final VoidCallback onCancel;
  final bool useCompactInterface;

  const MobileAudioInputWidget({
    super.key,
    required this.onAudioMessageSent,
    required this.onCancel,
    this.useCompactInterface = false,
  });

  @override
  State<MobileAudioInputWidget> createState() => _MobileAudioInputWidgetState();
}

class _MobileAudioInputWidgetState extends State<MobileAudioInputWidget> {
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
        
        if (widget.useCompactInterface) {
          return _buildCompactInterface(state, audioProvider);
        } else {
          return _buildFullInterface(state, audioProvider);
        }
      },
    );
  }

  Widget _buildCompactInterface(AudioState state, AudioProvider audioProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          // Indicador de gravação com filtro
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic,
                color: Colors.red[600],
                size: 18,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.noise_control_off,
                color: Colors.blue[600],
                size: 14,
              ),
            ],
          ),
          const SizedBox(width: 8),
          
          // Timer
                     Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text(
                 _formatDuration(state.recordDuration),
                 style: TextStyle(
                   color: Colors.red[600],
                   fontWeight: FontWeight.w600,
                   fontSize: 14,
                 ),
               ),
               const SizedBox(height: 2),
               // Barra de progresso do limite de tempo
               Container(
                 width: 40,
                 height: 2,
                 decoration: BoxDecoration(
                   color: Colors.grey[300],
                   borderRadius: BorderRadius.circular(1),
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
                       borderRadius: BorderRadius.circular(1),
                     ),
                   ),
                 ),
               ),
             ],
           ),
          
          const Spacer(),
          
          // Controles compactos
          Row(
            children: [
              // Botão de pausar/retomar
              if (state.recordingState == AudioRecordingState.recording)
                IconButton(
                  onPressed: () => audioProvider.pauseRecording(),
                  icon: Icon(
                    Icons.pause,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                )
              else if (state.recordingState == AudioRecordingState.paused)
                IconButton(
                  onPressed: () => audioProvider.resumeRecording(),
                  icon: Icon(
                    Icons.play_arrow,
                    color: Colors.green[600],
                    size: 20,
                  ),
                ),
              
              // Botão de cancelar
              IconButton(
                onPressed: () async {
                  await audioProvider.stopRecording();
                  widget.onCancel();
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              
              // Botão de enviar
              IconButton(
                onPressed: _handleSendAudio,
                icon: Icon(
                  Icons.send,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullInterface(AudioState state, AudioProvider audioProvider) {
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
          // Indicador de gravação com filtro
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.noise_control_off,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ],
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
              Text(
                _formatDuration(state.recordDuration),
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
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
  }
}

