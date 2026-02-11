import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';
import '../theme/m3_expressive.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/dialogs/confirmation_dialog.dart';
import '../widgets/task_breakdown_card.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const AIChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _initialMessageSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialMessage != null && !_initialMessageSent) {
        _initialMessageSent = true;
        _handleSubmit(widget.initialMessage!);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: M3ExpressiveMotion.pickDuration(
            reducedMotion: reducedMotion,
            normal: const Duration(milliseconds: 220),
            expressive: M3ExpressiveMotion.medium,
          ),
          curve: M3ExpressiveMotion.emphasizedDecelerate,
        );
      });
    }
  }

  void _showChatHistorySheet(ChatState chatState) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        if (chatState.sessions.isEmpty) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                l10n.noChatHistory,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.58,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.chatHistory,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    itemCount: chatState.sessions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final session = chatState.sessions[index];
                      final isCurrent =
                          session.id == chatState.currentSessionId;
                      final when = DateFormat(
                        'yyyy/MM/dd HH:mm',
                      ).format(session.updatedAt.toLocal());
                      return ListTile(
                        leading: Icon(
                          isCurrent
                              ? Icons.check_circle
                              : Icons.chat_bubble_outline,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(when),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          if (!isCurrent) {
                            await ref
                                .read(chatProvider.notifier)
                                .switchSession(session.id);
                            if (mounted) {
                              _scrollToBottom();
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    final chatNotifier = ref.read(chatProvider.notifier);

    await chatNotifier.addUserMessage(text.trim());
    _textController.clear();
    _scrollToBottom();

    await chatNotifier.generateAIResponse(text.trim());
    _scrollToBottom();
  }

  Future<void> _startNewChat() async {
    await ref.read(chatProvider.notifier).createNewSession();
    if (!mounted) {
      return;
    }
    _textController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _clearCurrentChat() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.clearConversation,
      content: l10n.confirmClearConversation,
      confirmText: l10n.clearConversationButton,
      isDangerous: true,
    );
    if (confirmed == true) {
      await ref.read(chatProvider.notifier).clearChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final chatState = ref.watch(chatProvider);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        surfaceTintColor: colorScheme.surfaceTint,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: chatState.isLoading
            ? Text(
                l10n.thinking,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                chatState.currentSession?.title ?? l10n.newChat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          TextButton.icon(
            onPressed: chatState.isLoading ? null : _startNewChat,
            icon: const Icon(Icons.add),
            label: Text(l10n.newChat),
          ),
          if (chatState.sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.chatHistory,
              onPressed: () => _showChatHistorySheet(chatState),
            ),
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.clearConversation,
              onPressed: _clearCurrentChat,
            ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!.startsWith('[AI_RESPONSE_FAILED]:')
                          ? '${l10n.aiResponseFailed}: ${chatState.error!.substring(21)}'
                          : chatState.error!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onErrorContainer,
                      size: 18,
                    ),
                    onPressed: () {
                      ref.read(chatProvider.notifier).clearError();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: l10n.close,
                  ),
                ],
              ),
            ),
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return Column(
                        children: [
                          if (message.content.isNotEmpty ||
                              message.taskPlan == null)
                            ChatMessageBubble(
                              message: message,
                              key: ValueKey(message.id),
                            ),
                          if (message.taskPlan != null)
                            TaskBreakdownCard(taskPlan: message.taskPlan!),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.typeMessage,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                      enabled: !chatState.isLoading,
                      onSubmitted: _handleSubmit,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    final canSend =
                        value.text.trim().isNotEmpty && !chatState.isLoading;
                    final reducedMotion =
                        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                    final duration = M3ExpressiveMotion.pickDuration(
                      reducedMotion: reducedMotion,
                      normal: const Duration(milliseconds: 180),
                      expressive: M3ExpressiveMotion.medium,
                    );

                    return AnimatedScale(
                      scale: canSend ? 1.1 : 1.0,
                      duration: duration,
                      curve: M3ExpressiveMotion.emphasizedDecelerate,
                      child: AnimatedContainer(
                        duration: duration,
                        curve: M3ExpressiveMotion.emphasizedStandard,
                        decoration: BoxDecoration(
                          gradient: canSend
                              ? LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                )
                              : null,
                          color: canSend
                              ? null
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            canSend ? 18 : 24,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              canSend ? 18 : 24,
                            ),
                            onTap: canSend
                                ? () => _handleSubmit(_textController.text)
                                : null,
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: canSend
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.4,
                                      ),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.helloAI,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aiDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
