import 'package:equatable/equatable.dart';
import 'medicine_entity.dart';

enum MessageSender {
  patient,
  doctor,
  system,
}

enum MessageLanguage {
  english;

  static MessageLanguage fromQuery(String text) => MessageLanguage.english;
}

class ChatMessage extends Equatable {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final List<MedicineEntity> verifiedReferences;
  final String? originalQuery;
  final MessageLanguage language;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.verifiedReferences = const [],
    this.originalQuery,
    this.language = MessageLanguage.english,
  });

  ChatMessage copyWith({
    String? id,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    List<MedicineEntity>? verifiedReferences,
    String? originalQuery,
    MessageLanguage? language,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      verifiedReferences: verifiedReferences ?? this.verifiedReferences,
      originalQuery: originalQuery ?? this.originalQuery,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isStreaming': isStreaming,
      'verifiedReferences': verifiedReferences.map((m) => m.toJson()).toList(),
      'originalQuery': originalQuery,
      'language': language.name,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => MessageSender.doctor,
      ),
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isStreaming: json['isStreaming'] as bool? ?? false,
      verifiedReferences: (json['verifiedReferences'] as List<dynamic>?)
              ?.map((item) => MedicineEntity.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      originalQuery: json['originalQuery'] as String?,
      language: MessageLanguage.english,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sender,
        content,
        timestamp,
        isStreaming,
        verifiedReferences,
        originalQuery,
        language,
      ];
}
