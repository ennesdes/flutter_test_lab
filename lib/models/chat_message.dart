enum MessageType {
  text,
  audio,
  image,
}

enum MessageSender {
  user,
  other,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final String? audioPath;
  final Duration? audioDuration;
  final String? imagePath;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.audioPath,
    this.audioDuration,
    this.imagePath,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
    String? audioPath,
    Duration? audioDuration,
    String? imagePath,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'audioPath': audioPath,
      'audioDuration': audioDuration?.inMilliseconds,
      'imagePath': imagePath,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      sender: MessageSender.values.firstWhere((e) => e.name == json['sender']),
      timestamp: DateTime.parse(json['timestamp']),
      audioPath: json['audioPath'],
      audioDuration: json['audioDuration'] != null 
          ? Duration(milliseconds: json['audioDuration'])
          : null,
      imagePath: json['imagePath'],
    );
  }
}
