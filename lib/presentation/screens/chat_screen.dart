import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../tabib.dart';

class ChatScreen extends StatefulWidget {
  final String modelPath;

  const ChatScreen({super.key, required this.modelPath});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  EmergencyCountryInfo _currentCountry =
      EmergencyService.instance.currentCountry;

  int? _editingMessageIndex;

  List<Map<String, String>> _getLocalizedQuickSymptoms() {
    return _currentCountry.suggestions.map((s) => s.toMap()).toList();
  }

  String _getInputHintText() {
    return _currentCountry.inputHint;
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    context.read<ChatBloc>().add(InitializeChatEvent(widget.modelPath));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (_editingMessageIndex != null && presetText == null) {
      context.read<ChatBloc>().add(
        EditUserMessageEvent(messageIndex: _editingMessageIndex!, text: text),
      );
      _editingMessageIndex = null;
    } else {
      context.read<ChatBloc>().add(SendUserMessageEvent(text));
    }

    if (presetText == null) {
      _textController.clear();
    }
    _focusNode.unfocus();
    _scrollToBottom();
  }

  void _copyToClipboard(String text, String message) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            AppGap.w8,
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppTheme.primaryTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _editPrompt(int index, String text) {
    setState(() {
      _editingMessageIndex = index;
      _textController.text = text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    });
    _focusNode.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            AppGap.w8,
            Text(
              'Editing message in place...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showCountrySelector() {
    EmergencyRegionBottomSheet.show(
      context,
      currentCountry: _currentCountry,
      onSelected: (item) {
        setState(() {
          _currentCountry = item;
          EmergencyService.instance.currentCountry = item;
        });
        context.read<ChatBloc>().add(ChangeCountryEvent(item));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width >= 650;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const _ChatHistoryDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryTeal, Color(0xFF00BFA5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tabib AI Doctor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  AppGap.h2,
                  Row(
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppGap.w4,
                      Text(
                        'Clinical Decision Support',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Start Fresh Consultation',
            onPressed: () {
              context.read<ChatBloc>().add(const ClearChatEvent());
              _textController.clear();
              _editingMessageIndex = null;
            },
          ),
          InkWell(
            onTap: _showCountrySelector,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentCountry.flagEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  AppGap.w4,
                  Text(
                    _currentCountry.countryCode,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
          AppGap.w10,
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 860,
        child: Column(
          children: [
            _buildEmergencyTriageBanner(context, isDark),
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  _scrollToBottom();
                },
                builder: (context, state) {
                  final messages = state.messages;

                  if (messages.isEmpty) {
                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      children: const [WelcomeCard()],
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      if (msg.id.startsWith('msg_welcome')) {
                        return const WelcomeCard();
                      }
                      return ChatMessageBubble(
                        message: msg,
                        isDark: isDark,
                        isTablet: isTablet,
                        activePrompt: _textController.text.isNotEmpty
                            ? _textController.text
                            : null,
                        onCopy: () => _copyToClipboard(
                          msg.content,
                          'Message copied to clipboard',
                        ),
                        onEditPrompt: msg.sender == MessageSender.patient
                            ? () => _editPrompt(index, msg.content)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            _buildQuickSymptomChips(isDark),
            _buildInputBar(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTriageBanner(BuildContext context, bool isDark) {
    return EmergencyBanner(
      currentCountry: _currentCountry,
      isDark: isDark,
      pulseAnimation: _pulseAnimation,
    );
  }

  Widget _buildQuickSymptomChips(bool isDark) {
    final chips = _getLocalizedQuickSymptoms();
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: chips.length,
        separatorBuilder: (_, index) => AppGap.w8,
        itemBuilder: (context, index) {
          final item = chips[index];
          return ActionChip(
            label: Text(
              item['label']!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF1A2640)
                : const Color(0xFFF1F5F9),
            side: BorderSide(
              color: isDark ? const Color(0xFF2E4065) : const Color(0xFFCBD5E1),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onPressed: () => _sendMessage(item['query']),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isGenerating = state is GeneratingTokenStream;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _getInputHintText(),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryTeal,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                AppGap.w8,
                if (isGenerating) ...[
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.emergencyRed,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    tooltip: 'Stop generation',
                    onPressed: () {
                      context.read<ChatBloc>().add(const StopGenerationEvent());
                    },
                  ),
                ] else ...[
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Consult Tabib',
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatHistoryDrawer extends StatefulWidget {
  const _ChatHistoryDrawer();

  @override
  State<_ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<_ChatHistoryDrawer> {
  List<ChatSession>? _sessions;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final list = await ChatHistoryLocalDb.instance.getAllSessions();
    if (mounted) {
      setState(() {
        _sessions = list;
      });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    await ChatHistoryLocalDb.instance.deleteSession(sessionId);
    if (!mounted) return;
    context.read<ChatBloc>().add(DeleteChatSessionEvent(sessionId));
    await _loadSessions();
  }

  void _confirmClearAll() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Consultations?'),
        content: const Text(
          'This will permanently delete all offline consultation sessions and chat records from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              context.read<ChatBloc>().add(const ClearAllHistoryEvent());
              Navigator.pop(dialogCtx);
              _loadSessions();
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSessionId = context.select<ChatBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is ChatIdle) return state.currentSessionId;
      if (state is GeneratingTokenStream) return state.currentSessionId;
      return null;
    });

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryTeal, Color(0xFF00BFA5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  AppGap.w10,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tabib AI Doctor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Clinical Decision Support',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close Drawer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            AppGap.h6,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<ChatBloc>().add(const StartNewSessionEvent());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_comment_rounded,
                          color: AppTheme.primaryTeal,
                          size: 20,
                        ),
                        AppGap.w10,
                        Text(
                          'New Consultation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AppGap.h14,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AppTheme.primaryTeal,
                  ),
                  AppGap.w6,
                  Text(
                    'Consultation History',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  if (_sessions != null && _sessions!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_sessions!.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AppGap.h6,
            Expanded(
              child: _sessions == null
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _sessions!.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            AppGap.h10,
                            Text(
                              'No previous consultations found',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      itemCount: _sessions!.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 3),
                      itemBuilder: (context, index) {
                        final session = _sessions![index];
                        final isCurrent = session.id == activeSessionId;
                        final dateStr = DateFormat('MMM d, hh:mm a')
                            .format(session.updatedAt);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              if (!isCurrent) {
                                context.read<ChatBloc>().add(
                                  LoadChatSessionEvent(session.id),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppTheme.primaryTeal.withValues(
                                        alpha: 0.12,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppTheme.primaryTeal.withValues(
                                          alpha: 0.4,
                                        )
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.chat_outlined,
                                        size: 15,
                                        color: isCurrent
                                            ? AppTheme.primaryTeal
                                            : (isDark
                                                  ? Colors.white38
                                                  : Colors.black38),
                                      ),
                                      AppGap.w8,
                                      Expanded(
                                        child: Text(
                                          session.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isCurrent
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isCurrent
                                                ? (isDark
                                                      ? Colors.white
                                                      : AppTheme.primaryTeal)
                                                : (isDark
                                                      ? Colors.white
                                                      : AppTheme
                                                            .lightTextPrimary),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                        ),
                                        tooltip: 'Delete consultation',
                                        onPressed: () =>
                                            _deleteSession(session.id),
                                      ),
                                    ],
                                  ),
                                  AppGap.h4,
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                      AppGap.w4,
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${session.messageCount} msg${session.messageCount == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  if (_sessions != null && _sessions!.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.emergencyRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onPressed: _confirmClearAll,
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'Clinical Decision Support',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

