import 'package:equatable/equatable.dart';
import '../../../domain/services/emergency_service.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChatEvent extends ChatEvent {
  final String modelPath;

  const InitializeChatEvent(this.modelPath);

  @override
  List<Object?> get props => [modelPath];
}

class SendUserMessageEvent extends ChatEvent {
  final String text;

  const SendUserMessageEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class EditUserMessageEvent extends ChatEvent {
  final int messageIndex;
  final String text;

  const EditUserMessageEvent({
    required this.messageIndex,
    required this.text,
  });

  @override
  List<Object?> get props => [messageIndex, text];
}

class ReceiveTokenStreamEvent extends ChatEvent {
  final String token;

  const ReceiveTokenStreamEvent(this.token);

  @override
  List<Object?> get props => [token];
}

class FinishTokenStreamEvent extends ChatEvent {
  const FinishTokenStreamEvent();
}

class StopGenerationEvent extends ChatEvent {
  const StopGenerationEvent();
}

class ClearChatEvent extends ChatEvent {
  const ClearChatEvent();
}

class ChangeCountryEvent extends ChatEvent {
  final EmergencyCountryInfo country;

  const ChangeCountryEvent(this.country);

  @override
  List<Object?> get props => [country.countryCode];
}

class LoadChatSessionEvent extends ChatEvent {
  final String sessionId;

  const LoadChatSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class StartNewSessionEvent extends ChatEvent {
  const StartNewSessionEvent();
}

class DeleteChatSessionEvent extends ChatEvent {
  final String sessionId;

  const DeleteChatSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ClearAllHistoryEvent extends ChatEvent {
  const ClearAllHistoryEvent();
}
