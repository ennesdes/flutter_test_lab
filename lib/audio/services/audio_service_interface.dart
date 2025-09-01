import 'dart:async';
import '../models/audio_state.dart';

abstract class AudioServiceInterface {
  Stream<AudioState> get audioStateStream;
  AudioState get currentState;
  
  // Recording
  Future<bool> requestPermissions();
  Future<void> startRecording({Duration? maxDuration});
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<String?> stopRecording();
  
  // Playback
  Future<void> startPlayback(String filePath);
  Future<void> pausePlayback();
  Future<void> resumePlayback();
  Future<void> stopPlayback();
  Future<void> setPlaybackSpeed(PlaybackSpeed speed);
  Future<void> seekTo(Duration position);
  
  // Platform specific
  Future<String> getStoragePath();
  Future<void> saveAudioFile(String sourcePath, String fileName);
  Future<bool> deleteAudioFile(String filePath);
  Future<List<String>> getAudioFiles();
  
  // Cleanup
  Future<void> dispose();
}

