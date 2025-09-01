import 'package:flutter/foundation.dart';
import '../models/audio_state.dart';
import '../services/audio_service_factory.dart';
import '../services/audio_service_interface.dart';

class AudioProvider extends ChangeNotifier {
  final AudioServiceInterface _audioService = AudioServiceFactory.create();
  
  AudioState get currentState => _audioService.currentState;
  Stream<AudioState> get audioStateStream => _audioService.audioStateStream;

  AudioProvider() {
    _audioService.audioStateStream.listen((state) {
      notifyListeners();
    });
  }

  // Recording methods
  Future<bool> requestPermissions() async {
    return await _audioService.requestPermissions();
  }

  Future<void> startRecording({Duration? maxDuration}) async {
    await _audioService.startRecording(maxDuration: maxDuration);
  }

  Future<void> pauseRecording() async {
    await _audioService.pauseRecording();
  }

  Future<void> resumeRecording() async {
    await _audioService.resumeRecording();
  }

  Future<String?> stopRecording() async {
    return await _audioService.stopRecording();
  }

  // Playback methods
  Future<void> startPlayback(String filePath) async {
    await _audioService.startPlayback(filePath);
  }

  Future<void> pausePlayback() async {
    await _audioService.pausePlayback();
  }

  Future<void> resumePlayback() async {
    await _audioService.resumePlayback();
  }

  Future<void> stopPlayback() async {
    await _audioService.stopPlayback();
  }

  Future<void> setPlaybackSpeed(PlaybackSpeed speed) async {
    await _audioService.setPlaybackSpeed(speed);
  }

  Future<void> seekTo(Duration position) async {
    await _audioService.seekTo(position);
  }

  // Platform specific
  Future<String> getStoragePath() async {
    return await _audioService.getStoragePath();
  }

  Future<void> saveAudioFile(String sourcePath, String fileName) async {
    await _audioService.saveAudioFile(sourcePath, fileName);
  }

  Future<bool> deleteAudioFile(String filePath) async {
    return await _audioService.deleteAudioFile(filePath);
  }

  Future<List<String>> getAudioFiles() async {
    return await _audioService.getAudioFiles();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
