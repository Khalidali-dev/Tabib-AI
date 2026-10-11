import 'package:equatable/equatable.dart';
import '../../../tabib.dart';

abstract class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final String currentSessionId;
  final String sessionTitle;

  const ChatState({
    this.messages = const [],
    this.currentSessionId = '',
    this.sessionTitle = '',
  });

  @override
  List<Object?> get props => [messages, currentSessionId, sessionTitle];
}

class ChatInitial extends ChatState {
  const ChatInitial()
      : super(
          messages: const [],
          currentSessionId: '',
          sessionTitle: '',
        );
}

class ChatIdle extends ChatState {
  const ChatIdle({
    super.messages,
    super.currentSessionId,
    super.sessionTitle,
  });

  @override
  List<Object?> get props => [messages, currentSessionId, sessionTitle];
}

class GeneratingTokenStream extends ChatState {
  final String currentStreamingId;
  final String? partialMessage;

  const GeneratingTokenStream({
    required super.messages,
    required this.currentStreamingId,
    this.partialMessage,
    super.currentSessionId,
    super.sessionTitle,
  });

  @override
  List<Object?> get props =>
      [messages, currentStreamingId, partialMessage, currentSessionId, sessionTitle];
}

/// Alias and specialized stream update state for assembled SOAP notes.
class ChatStreamUpdateState extends GeneratingTokenStream {
  const ChatStreamUpdateState({
    required super.messages,
    required super.currentStreamingId,
    required String partialMessage,
    super.currentSessionId,
    super.sessionTitle,
  }) : super(partialMessage: partialMessage);
}


class ChatSuccessState extends ChatState {
  final String? message;

  const ChatSuccessState({
    this.message,
    super.messages,
    super.currentSessionId,
    super.sessionTitle,
  });

  @override
  List<Object?> get props => [message, messages, currentSessionId, sessionTitle];
}

class ChatError extends ChatState {
  final String errorMessage;

  const ChatError({
    required this.errorMessage,
    super.messages,
    super.currentSessionId,
    super.sessionTitle,
  });

  @override
  List<Object?> get props =>
      [errorMessage, messages, currentSessionId, sessionTitle];
}
