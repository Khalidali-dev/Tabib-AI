import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../tabib.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MedicineLocalDb medicineDb;
  final MedicalInferenceService inferenceService;
  final ChatHistoryLocalDb historyDb;

  StreamSubscription<String>? _tokenStreamSubscription;
  String? _activeStreamingMessageId;
  String _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  String _sessionTitle = '';

  ChatBloc({
    MedicineLocalDb? medicineDb,
    MedicalInferenceService? inferenceService,
    ChatHistoryLocalDb? historyDb,
  })  : medicineDb = medicineDb ?? MedicineLocalDb.instance,
        inferenceService = inferenceService ?? MedicalInferenceService.instance,
        historyDb = historyDb ?? ChatHistoryLocalDb.instance,
        super(const ChatInitial()) {
    on<InitializeChatEvent>(_onInitializeChat);
    on<SendUserMessageEvent>(_onSendUserMessage);
    on<EditUserMessageEvent>(_onEditUserMessage);
    on<ReceiveTokenStreamEvent>(_onReceiveTokenStream);
    on<FinishTokenStreamEvent>(_onFinishTokenStream);
    on<StopGenerationEvent>(_onStopGeneration);
    on<ClearChatEvent>(_onClearChat);
    on<ChangeCountryEvent>(_onChangeCountry);
    on<LoadChatSessionEvent>(_onLoadChatSession);
    on<StartNewSessionEvent>(_onStartNewSession);
    on<DeleteChatSessionEvent>(_onDeleteChatSession);
    on<ClearAllHistoryEvent>(_onClearAllHistory);
  }

  Future<void> _onInitializeChat(
    InitializeChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await medicineDb.init();
      await historyDb.init();
      if (!inferenceService.isReady ||
          inferenceService.activeModelPath != event.modelPath) {
        await inferenceService.initContext(event.modelPath);
      }

      _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      _sessionTitle = '';

      final country = EmergencyService.instance.currentCountry;
      final welcomeMsg = ChatMessage(
        id: 'msg_welcome',
        sender: MessageSender.doctor,
        content: country.welcomeMessage,
        timestamp: DateTime.now(),
        isStreaming: false,
      );

      emit(ChatIdle(
        messages: [welcomeMsg],
        currentSessionId: _currentSessionId,
        sessionTitle: '',
      ));
    } catch (e) {
      emit(ChatError(
        errorMessage: 'Failed to initialize clinical AI engine: $e',
        messages: state.messages,
        currentSessionId: _currentSessionId,
        sessionTitle: _sessionTitle,
      ));
    }
  }

  Future<void> _onSendUserMessage(
    SendUserMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final queryText = event.text.trim();
    if (queryText.isEmpty) return;

    await _executeMessageProcessing(
      queryText: queryText,
      baseMessages: List<ChatMessage>.from(state.messages),
      emit: emit,
    );
  }

  Future<void> _onEditUserMessage(
    EditUserMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final queryText = event.text.trim();
    if (queryText.isEmpty) return;

    await _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = null;
    _activeStreamingMessageId = null;
    await inferenceService.stopGeneration();

    final truncatedMessages = <ChatMessage>[];
    if (event.messageIndex >= 0 && event.messageIndex < state.messages.length) {
      truncatedMessages.addAll(state.messages.sublist(0, event.messageIndex));
    } else {
      truncatedMessages.addAll(state.messages);
    }

    await _executeMessageProcessing(
      queryText: queryText,
      baseMessages: truncatedMessages,
      emit: emit,
    );
  }

  Future<void> _executeMessageProcessing({
    required String queryText,
    required List<ChatMessage> baseMessages,
    required Emitter<ChatState> emit,
  }) async {
    final triageResult = TriageInterceptor.evaluate(queryText);
    if (triageResult.isEmergency) {
      if (_sessionTitle.isEmpty) {
        _sessionTitle = queryText.length > 40
            ? '${queryText.substring(0, 37)}...'
            : queryText;
      }

      final patientMsg = ChatMessage(
        id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.patient,
        content: queryText,
        timestamp: DateTime.now(),
        isStreaming: false,
        language: MessageLanguage.english,
      );

      final emergencyDoctorMsg = ChatMessage(
        id: 'doctor_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.doctor,
        content: triageResult.emergencyMessage ?? '',
        timestamp: DateTime.now(),
        isStreaming: false,
        language: MessageLanguage.english,
      );

      final currentMessages = List<ChatMessage>.from(baseMessages)
        ..add(patientMsg)
        ..add(emergencyDoctorMsg);

      emit(ChatSuccessState(
        message: triageResult.emergencyMessage,
        messages: currentMessages,
        currentSessionId: _currentSessionId,
        sessionTitle: _sessionTitle,
      ));

      await historyDb.saveSessionMessages(
        sessionId: _currentSessionId,
        sessionTitle: _sessionTitle,
        messages: currentMessages,
      );
      return;
    }

    if (triageResult.directive != null) {
      if (_sessionTitle.isEmpty) {
        _sessionTitle = queryText.length > 40
            ? '${queryText.substring(0, 37)}...'
            : queryText;
      }

      final patientMsg = ChatMessage(
        id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.patient,
        content: queryText,
        timestamp: DateTime.now(),
        isStreaming: false,
        language: MessageLanguage.english,
      );

      final greetingDoctorMsg = ChatMessage(
        id: 'doctor_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.doctor,
        content: triageResult.directive!,
        timestamp: DateTime.now(),
        isStreaming: false,
        language: MessageLanguage.english,
      );

      final currentMessages = List<ChatMessage>.from(baseMessages)
        ..add(patientMsg)
        ..add(greetingDoctorMsg);

      emit(ChatIdle(
        messages: currentMessages,
        currentSessionId: _currentSessionId,
        sessionTitle: _sessionTitle,
      ));

      await historyDb.saveSessionMessages(
        sessionId: _currentSessionId,
        sessionTitle: _sessionTitle,
        messages: currentMessages,
      );
      return;
    }

    final normalized = InputNormalizer.normalize(queryText);

    if (_sessionTitle.isEmpty) {
      _sessionTitle = queryText.length > 40
          ? '${queryText.substring(0, 37)}...'
          : queryText;
    }

    final patientMsg = ChatMessage(
      id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.patient,
      content: queryText,
      timestamp: DateTime.now(),
      isStreaming: false,
      language: MessageLanguage.english,
    );

    final isSurgicalOrContraindicated =
        TriageInterceptor.isSurgicalEmergencyOrContraindicated(queryText) ||
            TriageInterceptor.isSurgicalEmergencyOrContraindicated(
                normalized.sanitizedPrompt);

    final searchTerms = normalized.searchQuery.isNotEmpty
        ? normalized.searchQuery
        : normalized.sanitizedPrompt;
    final dbRecord = isSurgicalOrContraindicated
        ? <MedicineEntity>[]
        : await MedicineLocalDb.search(searchTerms);

    final prompt = inferenceService.buildClinicalPrompt(
      query: normalized.sanitizedPrompt,
      context: dbRecord.toContextString(),
    );

    _activeStreamingMessageId =
        'doctor_${DateTime.now().millisecondsSinceEpoch}';
    final doctorMsg = ChatMessage(
      id: _activeStreamingMessageId!,
      sender: MessageSender.doctor,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
      verifiedReferences: isSurgicalOrContraindicated ? const [] : dbRecord,
      language: MessageLanguage.english,
    );

    final currentMessages = List<ChatMessage>.from(baseMessages)
      ..add(patientMsg)
      ..add(doctorMsg);

    emit(GeneratingTokenStream(
      messages: currentMessages,
      currentStreamingId: _activeStreamingMessageId!,
      currentSessionId: _currentSessionId,
      sessionTitle: _sessionTitle,
    ));

    await _tokenStreamSubscription?.cancel();
    final llmStream = inferenceService.infer(
      prompt: prompt,
      records: dbRecord,
      userQuery: queryText,
    );

    _tokenStreamSubscription = llmStream.listen(
      (chunk) {
        add(ReceiveTokenStreamEvent(chunk));
      },
      onError: (err) {
        add(const FinishTokenStreamEvent());
      },
      onDone: () {
        add(const FinishTokenStreamEvent());
      },
      cancelOnError: true,
    );
  }

  void _onReceiveTokenStream(
    ReceiveTokenStreamEvent event,
    Emitter<ChatState> emit,
  ) {
    if (_activeStreamingMessageId == null) return;

    final updated = state.messages.map((m) {
      if (m.id == _activeStreamingMessageId) {
        return m.copyWith(
          content: m.content + event.token,
          isStreaming: true,
        );
      }
      return m;
    }).toList();

    final streamingMsg = updated.firstWhere(
      (m) => m.id == _activeStreamingMessageId,
      orElse: () => updated.last,
    );

    emit(ChatStreamUpdateState(
      messages: updated,
      currentStreamingId: _activeStreamingMessageId!,
      partialMessage: streamingMsg.content,
      currentSessionId: _currentSessionId,
      sessionTitle: _sessionTitle,
    ));
  }

  void _onFinishTokenStream(
    FinishTokenStreamEvent event,
    Emitter<ChatState> emit,
  ) {
    _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = null;

    final lastPatientMsg = state.messages
        .reversed
        .firstWhere(
          (msg) => msg.sender == MessageSender.patient,
          orElse: () => ChatMessage(
            id: '',
            sender: MessageSender.patient,
            content: '',
            timestamp: DateTime.now(),
            isStreaming: false,
          ),
        );
    final lastUserQuery = lastPatientMsg.content;
    final effectiveQuery =
        '${lastPatientMsg.content} ${lastPatientMsg.originalQuery ?? ''}'.trim();

    final updated = state.messages.map((m) {
      if (m.id == _activeStreamingMessageId) {
        final assembled = assembleClinicalResponse(
          llmText: m.content,
          dbMedicine: m.verifiedReferences,
          userQuery: effectiveQuery.isNotEmpty ? effectiveQuery : lastUserQuery,
        );

        return m.copyWith(
          content: assembled,
          isStreaming: false,
        );
      }
      return m;
    }).toList();

    _activeStreamingMessageId = null;

    emit(ChatIdle(
      messages: updated,
      currentSessionId: _currentSessionId,
      sessionTitle: _sessionTitle,
    ));

    historyDb.saveSessionMessages(
      sessionId: _currentSessionId,
      sessionTitle: _sessionTitle,
      messages: updated,
    );
  }

  static String assembleClinicalResponse({
    required String llmText,
    List<MedicineEntity>? dbMedicine,
    String? userQuery,
  }) {
    return MedicalInferenceService.assembleClinicalResponse(
      llmText: llmText,
      dbMedicine: dbMedicine,
      userQuery: userQuery,
    );
  }

  Future<void> _onStopGeneration(
    StopGenerationEvent event,
    Emitter<ChatState> emit,
  ) async {
    await inferenceService.stopGeneration();
    add(const FinishTokenStreamEvent());
  }

  void _onClearChat(
    ClearChatEvent event,
    Emitter<ChatState> emit,
  ) {
    _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = null;
    _activeStreamingMessageId = null;
    inferenceService.resetContext();

    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _sessionTitle = '';

    final country = EmergencyService.instance.currentCountry;
    final welcomeMsg = ChatMessage(
      id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.doctor,
      content: country.welcomeMessage,
      timestamp: DateTime.now(),
      isStreaming: false,
    );

    emit(ChatIdle(
      messages: [welcomeMsg],
      currentSessionId: _currentSessionId,
      sessionTitle: '',
    ));
  }

  void _onChangeCountry(
    ChangeCountryEvent event,
    Emitter<ChatState> emit,
  ) {
    EmergencyService.instance.currentCountry = event.country;
    final msgs = List<ChatMessage>.from(state.messages);
    if (msgs.isEmpty ||
        (msgs.length == 1 && msgs.first.id.startsWith('msg_welcome'))) {
      final updatedWelcome = ChatMessage(
        id: 'msg_welcome',
        sender: MessageSender.doctor,
        content: event.country.welcomeMessage,
        timestamp: DateTime.now(),
        isStreaming: false,
      );
      emit(ChatIdle(
        messages: [updatedWelcome],
        currentSessionId: _currentSessionId,
        sessionTitle: _sessionTitle,
      ));
    }
  }

  Future<void> _onLoadChatSession(
    LoadChatSessionEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = null;
    _activeStreamingMessageId = null;
    await inferenceService.resetContext();

    final session = await historyDb.getSessionWithMessages(event.sessionId);
    if (session != null && session.messages.isNotEmpty) {
      _currentSessionId = session.id;
      _sessionTitle = session.title;
      emit(ChatIdle(
        messages: session.messages,
        currentSessionId: session.id,
        sessionTitle: session.title,
      ));
    }
  }

  void _onStartNewSession(
    StartNewSessionEvent event,
    Emitter<ChatState> emit,
  ) {
    _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = null;
    _activeStreamingMessageId = null;
    inferenceService.resetContext();

    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _sessionTitle = '';

    final country = EmergencyService.instance.currentCountry;
    final welcomeMsg = ChatMessage(
      id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.doctor,
      content: country.welcomeMessage,
      timestamp: DateTime.now(),
      isStreaming: false,
    );

    emit(ChatIdle(
      messages: [welcomeMsg],
      currentSessionId: _currentSessionId,
      sessionTitle: '',
    ));
  }

  Future<void> _onDeleteChatSession(
    DeleteChatSessionEvent event,
    Emitter<ChatState> emit,
  ) async {
    await historyDb.deleteSession(event.sessionId);
    if (event.sessionId == _currentSessionId) {
      add(const StartNewSessionEvent());
    }
  }

  Future<void> _onClearAllHistory(
    ClearAllHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    await historyDb.clearAllSessions();
    add(const StartNewSessionEvent());
  }

  @override
  Future<void> close() {
    _tokenStreamSubscription?.cancel();
    return super.close();
  }
}
