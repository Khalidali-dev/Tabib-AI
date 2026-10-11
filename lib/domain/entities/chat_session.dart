import 'package:equatable/equatable.dart';
import 'chat_message.dart';

/// Represents a persistent consultation session history in Tabib.
class ChatSession extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String previewSnippet;
  final int messageCount;
  final List<ChatMessage> messages;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.previewSnippet,
    this.messageCount = 0,
    this.messages = const [],
  });

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? previewSnippet,
    int? messageCount,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      previewSnippet: previewSnippet ?? this.previewSnippet,
      messageCount: messageCount ?? this.messageCount,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        updatedAt,
        previewSnippet,
        messageCount,
        messages,
      ];
}
