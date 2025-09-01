import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/providers/audio_provider.dart';
import '../audio/models/audio_state.dart';
import '../models/chat_message.dart';

class AudioMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isUserMessage;

  const AudioMessageWidget({
    super.key,
    required this.message,
    required this.isUserMessage,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  PlaybackSpeed _currentSpeed = PlaybackSpeed.x1;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getSpeedText(PlaybackSpeed speed) {
    switch (speed) {
      case PlaybackSpeed.x1:
        return '1x';
      case PlaybackSpeed.x1_5:
        return '1.5x';
      case PlaybackSpeed.x2:
        return '2x';
    }
  }

  void _togglePlayback() {
    final audioProvider = context.read<AudioProvider>();
    final state = audioProvider.currentState;
    
    if (widget.message.audioPath == state.filePath && 
        (state.playbackState == AudioRecordingState.playing || 
         state.playbackState == AudioRecordingState.playingPaused)) {
      // Este áudio já está tocando
      if (state.playbackState == AudioRecordingState.playing) {
        audioProvider.pausePlayback();
      } else {
        audioProvider.resumePlayback();
      }
    } else {
      // Iniciar reprodução deste áudio
      if (widget.message.audioPath != null) {
        audioProvider.startPlayback(widget.message.audioPath!);
      }
    }
  }

  void _changeSpeed() {
    final audioProvider = context.read<AudioProvider>();
    PlaybackSpeed newSpeed;
    
    switch (_currentSpeed) {
      case PlaybackSpeed.x1:
        newSpeed = PlaybackSpeed.x1_5;
        break;
      case PlaybackSpeed.x1_5:
        newSpeed = PlaybackSpeed.x2;
        break;
      case PlaybackSpeed.x2:
        newSpeed = PlaybackSpeed.x1;
        break;
    }
    
    setState(() {
      _currentSpeed = newSpeed;
    });
    
    audioProvider.setPlaybackSpeed(newSpeed);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final state = audioProvider.currentState;
        
        // Verificar se este áudio está tocando
        final isThisAudioPlaying = widget.message.audioPath == state.filePath &&
            state.playbackState == AudioRecordingState.playing;
        
        final isThisAudioPaused = widget.message.audioPath == state.filePath &&
            state.playbackState == AudioRecordingState.playingPaused;
        
        // Atualizar posição se este áudio está tocando
        if (widget.message.audioPath == state.filePath) {
          _currentPosition = state.playbackPosition;
          _totalDuration = state.totalDuration;
        }
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isUserMessage 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isUserMessage 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com ícone e duração
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    size: 16,
                    color: widget.isUserMessage 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mensagem de áudio',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isUserMessage 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Indicador de volume máximo e filtros
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_up,
                        size: 14,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MAX',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.noise_control_off,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FILTRO',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.message.audioDuration != null
                        ? _formatDuration(widget.message.audioDuration!)
                        : _formatDuration(_totalDuration),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Controles de reprodução
              Row(
                children: [
                  // Botão play/pause
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isUserMessage 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isThisAudioPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Barra de progresso
                  Expanded(
                    child: Column(
                      children: [
                        // Slider de progresso
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: widget.isUserMessage 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                            inactiveTrackColor: Colors.grey[300],
                            thumbColor: widget.isUserMessage 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
                          child: Slider(
                            value: _totalDuration.inMilliseconds > 0
                                ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
                                : 0.0,
                            onChanged: (value) {
                              if (_totalDuration.inMilliseconds > 0) {
                                final newPosition = Duration(
                                  milliseconds: (value * _totalDuration.inMilliseconds).round(),
                                );
                                context.read<AudioProvider>().seekTo(newPosition);
                              }
                            },
                          ),
                        ),
                        
                        // Tempo atual / total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botão de velocidade
                  GestureDetector(
                    onTap: _changeSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSpeedText(_currentSpeed),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

