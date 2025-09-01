import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import '../models/audio_state.dart';
import 'audio_service_interface.dart';

class MobileAudioService implements AudioServiceInterface {
  final AudioRecorder _record = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  MobileAudioService() {
    _initializeAudioPlayer();
  }
  
  void _initializeAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      print('Estado do player: ${state.processingState} - ${state.playing}');
      
      // Atualizar estado baseado no processing state
      if (state.processingState == ProcessingState.ready) {
        _audioStateController.add(
          _audioStateController.value.copyWith(
            playbackState: AudioRecordingState.stopped,
          )
        );
      } else if (state.processingState == ProcessingState.completed) {
        _audioStateController.add(
          _audioStateController.value.copyWith(
            playbackState: AudioRecordingState.stopped,
            playbackPosition: Duration.zero,
          )
        );
      } else if (state.processingState == ProcessingState.loading) {
        print('Player está carregando...');
      } else if (state.processingState == ProcessingState.buffering) {
        print('Player está fazendo buffer...');
      }
    });
    
    // Configurar volume inicial ao MÁXIMO
    _audioPlayer.setVolume(1.0);
    print('Volume configurado ao máximo: 1.0');
    
    // Configurar para não fazer loop
    _audioPlayer.setLoopMode(LoopMode.off);
    
    // Configurações de áudio de alta qualidade
    print('Configurações de áudio de alta qualidade ativadas');
    print('- Volume máximo: 1.0');
    print('- Loop desativado');
    print('- Filtros de ruído ativos na gravação');
  }
  
  final BehaviorSubject<AudioState> _audioStateController = 
      BehaviorSubject<AudioState>.seeded(const AudioState());
  
  Timer? _recordingTimer;
  Timer? _playbackTimer;
  DateTime? _recordingStartTime;
  DateTime? _pauseStartTime;
  Duration _totalPauseTime = Duration.zero;
  
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
    final status = await Permission.microphone.request();
    final hasPermission = status.isGranted;
    
    _audioStateController.add(
      _audioStateController.value.copyWith(hasPermission: hasPermission)
    );
    
    return hasPermission;
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
      _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';
      
      await _record.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          // Configurações de filtro de ruído
          echoCancel: true,           // Cancelamento de eco
          noiseSuppress: true,        // Supressão de ruído
          autoGain: true,             // Controle automático de ganho
        ),
        path: _currentRecordingPath!,
      );
      
      print('Gravação iniciada com filtros de ruído ativados');
      
      _recordingStartTime = DateTime.now();
      _totalPauseTime = Duration.zero;
      
      // Definir limite de tempo (padrão 3 minutos)
      _currentMaxDuration = maxDuration ?? const Duration(minutes: 3);
      
      _startRecordingTimer(_currentMaxDuration!);
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          recordingState: AudioRecordingState.recording,
          recordDuration: Duration.zero,
          maxRecordDuration: _currentMaxDuration!,
        )
      );
    } catch (e) {
      print('Erro ao iniciar gravação mobile: $e');
    }
  }

  @override
  Future<void> pauseRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.recording) {
      try {
        await _record.pause();
        _pauseStartTime = DateTime.now();
        _recordingTimer?.cancel();
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            recordingState: AudioRecordingState.paused,
          )
        );
      } catch (e) {
        print('Erro ao pausar gravação mobile: $e');
      }
    }
  }

  @override
  Future<void> resumeRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.paused) {
      try {
        await _record.resume();
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
        print('Erro ao retomar gravação mobile: $e');
      }
    }
  }

  @override
  Future<String?> stopRecording() async {
    if (_audioStateController.value.recordingState == AudioRecordingState.recording ||
        _audioStateController.value.recordingState == AudioRecordingState.paused) {
      try {
        final path = await _record.stop();
        _recordingTimer?.cancel();
        _playbackTimer?.cancel();
        
        _audioStateController.add(
          _audioStateController.value.copyWith(
            recordingState: AudioRecordingState.stopped,
            filePath: path,
          )
        );
        
        return path;
      } catch (e) {
        print('Erro ao parar gravação mobile: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> startPlayback(String filePath) async {
    try {
      print('Iniciando reprodução do arquivo: $filePath');
      
      // Verificar se o arquivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        print('Arquivo não encontrado: $filePath');
        return;
      }
      
      print('Arquivo encontrado, tamanho: ${await file.length()} bytes');
      
      // Parar qualquer reprodução atual
      await _audioPlayer.stop();
      
      // Configurar o arquivo
      await _audioPlayer.setFilePath(filePath);
      print('Arquivo configurado no player');
      
      // Garantir volume máximo imediatamente após configurar o arquivo
      await _audioPlayer.setVolume(1.0);
      print('Volume definido ao máximo após configurar arquivo');
      
      // Aguardar o player estar pronto
      bool isReady = false;
      int attempts = 0;
      const maxAttempts = 50; // 5 segundos máximo
      
      while (!isReady && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        final state = _audioPlayer.processingState;
        print('Tentativa $attempts - Estado: $state');
        
        if (state == ProcessingState.ready) {
          isReady = true;
          print('Player está pronto!');
        }
        attempts++;
      }
      
      if (!isReady) {
        print('Player não ficou pronto após $maxAttempts tentativas');
        return;
      }
      
      // Verificar se o arquivo foi carregado
      final duration = _audioPlayer.duration;
      print('Duração do áudio: $duration');
      
      if (duration == null || duration == Duration.zero) {
        print('Duração inválida, não é possível reproduzir');
        return;
      }
      
      // Garantir volume máximo antes de reproduzir
      await _audioPlayer.setVolume(1.0);
      print('Volume definido ao máximo antes da reprodução');
      
      // Iniciar reprodução
      await _audioPlayer.play();
      print('Comando de play enviado');
      
      _currentPlaybackPath = filePath;
      _startPlaybackTimer();
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          playbackState: AudioRecordingState.playing,
          filePath: filePath,
          totalDuration: duration,
        )
      );
      
      print('Reprodução iniciada com sucesso');
    } catch (e) {
      print('Erro ao iniciar reprodução mobile: $e');
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
      print('Erro ao pausar reprodução mobile: $e');
    }
  }

  @override
  Future<void> resumePlayback() async {
    try {
      // Garantir volume máximo ao retomar
      await _audioPlayer.setVolume(1.0);
      print('Volume definido ao máximo ao retomar reprodução');
      
      await _audioPlayer.play();
      _startPlaybackTimer();
      
      _audioStateController.add(
        _audioStateController.value.copyWith(
          playbackState: AudioRecordingState.playing,
        )
      );
    } catch (e) {
      print('Erro ao retomar reprodução mobile: $e');
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
      print('Erro ao parar reprodução mobile: $e');
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
      print('Erro ao definir velocidade mobile: $e');
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
      print('Erro ao buscar posição mobile: $e');
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
      print('Erro ao salvar arquivo mobile: $e');
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
      print('Erro ao deletar arquivo mobile: $e');
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
          .where((file) => file.path.endsWith('.m4a') || file.path.endsWith('.mp3'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Erro ao listar arquivos mobile: $e');
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    await _record.dispose();
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
        print('Erro no timer de reprodução: $e');
      }
    });
  }
}

