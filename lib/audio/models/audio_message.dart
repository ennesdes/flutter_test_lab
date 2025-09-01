class AudioMessage {
  final String id;
  final String filePath;
  final Duration duration;
  final List<double> waveformData;
  final DateTime createdAt;

  AudioMessage({
    required this.id,
    required this.filePath,
    required this.duration,
    required this.waveformData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'waveformData': waveformData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AudioMessage.fromJson(Map<String, dynamic> json) {
    return AudioMessage(
      id: json['id'],
      filePath: json['filePath'],
      duration: Duration(milliseconds: json['duration']),
      waveformData: List<double>.from(json['waveformData']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

