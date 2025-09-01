import 'package:equatable/equatable.dart';

enum AudioRecordingState {
  idle,
  recording,
  paused,
  stopped,
  playing,
  playingPaused
}

enum PlaybackSpeed { x1, x1_5, x2 }

class AudioState extends Equatable {
  final AudioRecordingState recordingState;
  final AudioRecordingState playbackState;
  final Duration recordDuration;
  final Duration maxRecordDuration;
  final Duration playbackPosition;
  final Duration totalDuration;
  final List<double> waveformData;
  final double amplitude;
  final PlaybackSpeed playbackSpeed;
  final String? filePath;
  final bool hasPermission;

  const AudioState({
    this.recordingState = AudioRecordingState.idle,
    this.playbackState = AudioRecordingState.idle,
    this.recordDuration = Duration.zero,
    this.maxRecordDuration = const Duration(minutes: 3),
    this.playbackPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.waveformData = const [],
    this.amplitude = 0.0,
    this.playbackSpeed = PlaybackSpeed.x1,
    this.filePath,
    this.hasPermission = false,
  });

  AudioState copyWith({
    AudioRecordingState? recordingState,
    AudioRecordingState? playbackState,
    Duration? recordDuration,
    Duration? maxRecordDuration,
    Duration? playbackPosition,
    Duration? totalDuration,
    List<double>? waveformData,
    double? amplitude,
    PlaybackSpeed? playbackSpeed,
    String? filePath,
    bool? hasPermission,
  }) {
    return AudioState(
      recordingState: recordingState ?? this.recordingState,
      playbackState: playbackState ?? this.playbackState,
      recordDuration: recordDuration ?? this.recordDuration,
      maxRecordDuration: maxRecordDuration ?? this.maxRecordDuration,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      waveformData: waveformData ?? this.waveformData,
      amplitude: amplitude ?? this.amplitude,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      filePath: filePath ?? this.filePath,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }

  @override
  List<Object?> get props => [
    recordingState,
    playbackState,
    recordDuration,
    maxRecordDuration,
    playbackPosition,
    totalDuration,
    waveformData,
    amplitude,
    playbackSpeed,
    filePath,
    hasPermission,
  ];
}

