import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import '../models/audio_state.dart';
import 'audio_service_interface.dart';

class DesktopAudioService implements AudioServiceInterface {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final BehaviorSubject<AudioState> _audioStateController = 
      BehaviorSubject<AudioState>.seeded(const AudioState());
  
  Timer? _recordingTimer;
  Timer? _playbackTimer;
  DateTime? _recordingStartTime;
  DateTime? _pauseStartTime;
  Duration _totalPauseTime = Duration.zero;
  
  Process? _recordingProcess;
  String? _currentRecordingPath;
  String? _currentPlaybackPath;
  String? _storagePath;
  Duration? _currentMaxDuration;

  @override
  Stream<AudioState> get audioStateStream => _audioStateController.stream;

  @override
  AudioState get currentState => _audioStateController.value;

  @override
  Future<bool> requestPermissions() async {
    // No desktop, geralmente não precisamos de permissões especiais
    // mas podemos verificar se temos acesso ao microfone
    try {
      // Verificar se o sistema tem ferramentas de gravação disponíveis
      final result = await Process.run('which', ['ffmpeg']);
      final hasPermission = result.exitCode == 0;
      
      _audioStateController.add(
        _audioStateController.value.copyWith(hasPermission: hasPermission)
      );
      
      return hasPermission;
    } catch (e) {
      print('Erro ao verificar permissões desktop: $e');
      _audioStateController.add(
        _audioStateController.value.copyWith(hasPermission: false)
      );
      return false;
    }
  }

  @override
  Future<void> startRecording({Duration? maxDuration}) async {
    if (!_audioStateController.value.hasPermission) {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.wav';
      
      // Usar ffmpeg para gravação (disponível na maioria dos sistemas desktop)
      final arguments = [
        '-f', 'avfoundation', // macOS
        '-i', ':0', // Dispositivo de entrada padrão
        '-acodec', 'pcm_s16le',
        '-ar', '44100',
        '-ac', '1',
        _currentRecordingPath!,
      ];
      
      // Para Linux, usar ALSA
      if (Platform.isLinux) {
        arguments[1] = 'alsa';
      }
      
      // Para Windows, usar DirectShow
      if (Platform.isWindows) {
        arguments[1] = 'dshow';
        arguments[2] = 'audio=Microphone';
      }
      
      _recordingProcess = await Process.start('ffmpeg', arguments);
      
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
      print('Erro ao iniciar gravação desktop: $e');
      // Fallback: simular gravação para desenvolvimento
      _simulateRecording();
    }
  }

  void _simulateRecording() {
    _recordingStartTime = DateTime.now();
    _totalPauseTime = Duration.zero;
    _currentMaxDuration = const Duration(minutes: 3);
    _startRecordingTimer(_currentMaxDuration!);
    
    _audioStateController.add(
      _audioStateController.value.copyWith(
        recordingState: AudioRecordingState.recording,
        recordDuration: Duration.zero,
      )
    );
  }

  @override
  Future<void> pauseRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.recording) {
      try {
        _recordingProcess?.kill(ProcessSignal.sigstop);
        _pauseStartTime = DateTime.now();
        _recordingTimer?.cancel();
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            recordingState: AudioRecordingState.paused,
          )
        );
      } catch (e) {
        print('Erro ao pausar gravação desktop: $e');
      }
    }
  }

  @override
  Future<void> resumeRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.paused) {
      try {
        _recordingProcess?.kill(ProcessSignal.sigcont);
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
        print('Erro ao retomar gravação desktop: $e');
      }
    }
  }

  @override
  Future<String?> stopRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.recording ||
        _audioStateController.value.recordingState == AudioRecordingState.paused) {
      try {
        _recordingProcess?.kill();
        _recordingTimer?.cancel();
        _playbackTimer?.cancel();
        
        // Aguardar o processo terminar
        await _recordingProcess?.exitCode;
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            recordingState: AudioRecordingState.stopped,
            filePath: _currentRecordingPath,
          )
        );
        
        return _currentRecordingPath;
      } catch (e) {
        print('Erro ao parar gravação desktop: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> startPlayback(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);
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
      print('Erro ao iniciar reprodução desktop: $e');
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
      print('Erro ao pausar reprodução desktop: $e');
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
      print('Erro ao retomar reprodução desktop: $e');
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
      print('Erro ao parar reprodução desktop: $e');
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
      print('Erro ao definir velocidade desktop: $e');
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
      print('Erro ao buscar posição desktop: $e');
    }
  }

  @override
  Future<String> getStoragePath() async {
    if (_storagePath != null) return _storagePath!;
    
    final directory = await getApplicationDocumentsDirectory();
    _storagePath = '${directory.path}/audio_messages';
    
    // Criar diretório se não existir
    final dir = Directory(_storagePath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return _storagePath!;
  }

  @override
  Future<void> saveAudioFile(String sourcePath, String fileName) async {
    try {
      final storagePath = await getStoragePath();
      final destinationPath = '$storagePath/$fileName';
      
      final sourceFile = File(sourcePath);
      final destinationFile = File(destinationPath);
      
      await sourceFile.copy(destinationPath);
    } catch (e) {
      print('Erro ao salvar arquivo desktop: $e');
    }
  }

  @override
  Future<bool> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao deletar arquivo desktop: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getAudioFiles() async {
    try {
      final storagePath = await getStoragePath();
      final directory = Directory(storagePath);
      
      if (!await directory.exists()) return [];
      
      final files = await directory.list().toList();
      return files
          .where((file) => file.path.endsWith('.wav') || 
                          file.path.endsWith('.mp3') || 
                          file.path.endsWith('.m4a'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Erro ao listar arquivos desktop: $e');
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _recordingProcess?.kill();
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

