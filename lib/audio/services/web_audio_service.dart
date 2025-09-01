import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/audio_state.dart';
import 'audio_service_interface.dart';

class WebAudioService implements AudioServiceInterface {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final BehaviorSubject<AudioState> _audioStateController = 
      BehaviorSubject<AudioState>.seeded(const AudioState());
  
  Timer? _recordingTimer;
  Timer? _playbackTimer;
  DateTime? _recordingStartTime;
  DateTime? _pauseStartTime;
  Duration _totalPauseTime = Duration.zero;
  
  String? _currentRecordingPath;
  String? _currentPlaybackPath;
  Duration? _currentMaxDuration;

  @override
  Stream<AudioState> get audioStateStream => _audioStateController.stream;

  @override
  AudioState get currentState => _audioStateController.value;

  @override
  Future<bool> requestPermissions() async {
    // No web, as permissões são solicitadas automaticamente
    // Vamos simular que sempre temos permissão
    _audioStateController.add(
      _audioStateController.value.copyWith(hasPermission: true)
    );
    return true;
  }

  @override
  Future<void> startRecording({Duration? maxDuration}) async {
    try {
      // Simular gravação no web (sem MediaRecorder por simplicidade)
      _recordingStartTime = DateTime.now();
      _totalPauseTime = Duration.zero;
      
      // Definir limite de tempo (padrão 3 minutos)
      _currentMaxDuration = maxDuration ?? const Duration(minutes: 3);
      
      _startRecordingTimer(_currentMaxDuration!);
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          recordingState: AudioRecordingState.recording,
          recordDuration: Duration.zero,
        )
      );
    } catch (e) {
      print('Erro ao iniciar gravação web: $e');
    }
  }

  @override
  Future<void> pauseRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.recording) {
      try {
        _pauseStartTime = DateTime.now();
        _recordingTimer?.cancel();
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            recordingState: AudioRecordingState.paused,
          )
        );
      } catch (e) {
        print('Erro ao pausar gravação web: $e');
      }
    }
  }

  @override
  Future<void> resumeRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.paused) {
      try {
        if (_pauseStartTime != null) {
          _totalPauseTime += DateTime.now().difference(_pauseStartTime!);
          _pauseStartTime = null;
        }
        
        _startRecordingTimer(_currentMaxDuration!);
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            recordingState: AudioRecordingState.recording,
          )
        );
      } catch (e) {
        print('Erro ao retomar gravação web: $e');
      }
    }
  }

  @override
  Future<String?> stopRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.recording ||
        _audioStateController.value.recordingState == AudioRecordingState.paused) {
      try {
        _recordingTimer?.cancel();
        _playbackTimer?.cancel();
        
        // Gerar um ID único para o áudio
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = 'web_audio_$timestamp';
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            recordingState: AudioRecordingState.stopped,
            filePath: _currentRecordingPath,
          )
        );
        
        return _currentRecordingPath;
      } catch (e) {
        print('Erro ao parar gravação web: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> startPlayback(String filePath) async {
    try {
      // Para web, vamos usar um áudio de exemplo ou simular
      // Em produção, você pode usar um arquivo real ou URL
      await _audioPlayer.setUrl('https://www.soundjay.com/misc/sounds/bell-ringing-05.wav');
      await _audioPlayer.play();
      
      _currentPlaybackPath = filePath;
      _startPlaybackTimer();
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          playbackState: AudioRecordingState.playing,
          filePath: filePath,
        )
      );
      
      // Escutar quando o áudio terminar
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _audioStateController.add(
            _audioStateController.value.copyWith(
              playbackState: AudioRecordingState.stopped,
              playbackPosition: Duration.zero,
            )
          );
        }
      });
    } catch (e) {
      print('Erro ao iniciar reprodução web: $e');
    }
  }

  @override
  Future<void> pausePlayback() async {
    try {
      await _audioPlayer.pause();
      _playbackTimer?.cancel();
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          playbackState: AudioRecordingState.playingPaused,
        )
      );
    } catch (e) {
      print('Erro ao pausar reprodução web: $e');
    }
  }

  @override
  Future<void> resumePlayback() async {
    try {
      await _audioPlayer.play();
      _startPlaybackTimer();
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          playbackState: AudioRecordingState.playing,
        )
      );
    } catch (e) {
      print('Erro ao retomar reprodução web: $e');
    }
  }

  @override
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _playbackTimer?.cancel();
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          playbackState: AudioRecordingState.stopped,
          playbackPosition: Duration.zero,
        )
      );
    } catch (e) {
      print('Erro ao parar reprodução web: $e');
    }
  }

  @override
  Future<void> setPlaybackSpeed(PlaybackSpeed speed) async {
    double speedValue;
    switch (speed) {
      case PlaybackSpeed.x1:
        speedValue = 1.0;
        break;
      case PlaybackSpeed.x1_5:
        speedValue = 1.5;
        break;
      case PlaybackSpeed.x2:
        speedValue = 2.0;
        break;
    }
    
    try {
      await _audioPlayer.setSpeed(speedValue);
      _audioStateController.add(
        _audioStateController.value.copyWith(playbackSpeed: speed)
      );
    } catch (e) {
      print('Erro ao definir velocidade web: $e');
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _audioStateController.add(
        _audioStateController.value.copyWith(playbackPosition: position)
      );
    } catch (e) {
      print('Erro ao buscar posição web: $e');
    }
  }

  @override
  Future<String> getStoragePath() async {
    return 'web_storage';
  }

  @override
  Future<void> saveAudioFile(String sourcePath, String fileName) async {
    // No web, os arquivos são simulados
    print('Arquivo salvo no web: $fileName');
  }

  @override
  Future<bool> deleteAudioFile(String filePath) async {
    // No web, os arquivos são simulados
    print('Arquivo deletado no web: $filePath');
    return true;
  }

  @override
  Future<List<String>> getAudioFiles() async {
    // Retornar lista simulada de arquivos
    return ['web_audio_1', 'web_audio_2', 'web_audio_3'];
  }

  @override
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    await _audioPlayer.dispose();
    await _audioStateController.close();
  }

  void _startRecordingTimer(Duration maxDuration) {
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null) {
        final elapsed = DateTime.now().difference(_recordingStartTime!) - _totalPauseTime;
        
        // Verificar se atingiu o limite de tempo
        if (elapsed >= maxDuration) {
          stopRecording();
          timer.cancel();
          return;
        }
        
        _audioStateController.add(
          _audioStateController.value.copyWith(recordDuration: elapsed)
        );
      }
    });
  }

  void _startPlaybackTimer() {
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final position = _audioPlayer.position;
        final duration = _audioPlayer.duration ?? Duration.zero;
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            playbackPosition: position,
            totalDuration: duration,
          )
        );
      } catch (e) {
        // Ignorar erros durante a atualização do timer
      }
    });
  }
}
