import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../config/api_config.dart';
import '../services/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatState {
  final List<ChatMessage> messages;
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.sessions = const [],
    this.currentSessionId,
    this.isLoading = false,
    this.error,
  });

  ChatSession? get currentSession {
    if (currentSessionId == null) {
      return null;
    }
    for (final session in sessions) {
      if (session.id == currentSessionId) {
        return session;
      }
    }
    return null;
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatSession>? sessions,
    String? currentSessionId,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState()) {
    _initializeChat();
  }

  final _uuid = const Uuid();
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> _initializeChat() async {
    try {
      final sessions = await _db.getChatSessions();
      if (sessions.isEmpty) {
        final created = await _db.createChatSession(title: 'New Chat');
        state = state.copyWith(
          sessions: [created],
          currentSessionId: created.id,
          messages: const [],
        );
        return;
      }
      final currentSession = sessions.first;
      final messages = await _db.getChatMessages(currentSession.id);
      state = state.copyWith(
        sessions: sessions,
        currentSessionId: currentSession.id,
        messages: messages,
      );
    } catch (e) {
      debugPrint('Failed to initialize chat: $e');
    }
  }

  Future<void> _reloadSessions({String? currentSessionId}) async {
    final sessions = await _db.getChatSessions();
    state = state.copyWith(
      sessions: sessions,
      currentSessionId: currentSessionId ?? state.currentSessionId,
    );
  }

  String _titleFromPrompt(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return 'New Chat';
    }
    return normalized.length > 32
        ? '${normalized.substring(0, 32).trim()}...'
        : normalized;
  }

  Future<void> createNewSession() async {
    try {
      final session = await _db.createChatSession(title: 'New Chat');
      await _reloadSessions(currentSessionId: session.id);
      state = state.copyWith(messages: const [], error: null);
    } catch (e) {
      debugPrint('Failed to create chat session: $e');
    }
  }

  Future<void> switchSession(String sessionId) async {
    try {
      final messages = await _db.getChatMessages(sessionId);
      await _reloadSessions(currentSessionId: sessionId);
      state = state.copyWith(messages: messages, error: null);
    } catch (e) {
      debugPrint('Failed to switch chat session: $e');
    }
  }

  // 添加用戶訊息
  Future<void> addUserMessage(String content) async {
    final sessionId = state.currentSessionId;
    if (sessionId == null) {
      await _initializeChat();
    }
    final activeSessionId = state.currentSessionId;
    if (activeSessionId == null) {
      return;
    }
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, message]);
    try {
      await _db.insertChatMessage(message, sessionId: activeSessionId);
      final current = state.currentSession;
      final shouldRename =
          current != null &&
          (current.title.trim().isEmpty || current.title.trim() == 'New Chat');
      await _db.touchChatSession(
        activeSessionId,
        title: shouldRename ? _titleFromPrompt(content) : null,
      );
      await _reloadSessions(currentSessionId: activeSessionId);
    } catch (e) {
      debugPrint('Failed to persist user message: $e');
    }
  }

  // 使用後端 API 生成 AI 回覆（支援 streaming）
  Future<void> generateAIResponse(String userMessage) async {
    // 添加一個空的 AI 訊息作為佔位符
    final aiMessageId = _uuid.v4();
    final aiMessage = ChatMessage(
      id: aiMessageId,
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, aiMessage],
      isLoading: true,
      error: null,
    );

    try {
      // 準備歷史記錄
      final history = state.messages
          .where((msg) => msg.id != aiMessageId)
          .map(
            (msg) => {
              'role': msg.role == MessageRole.user ? 'user' : 'assistant',
              'content': msg.content,
            },
          )
          .toList();

      // 發送請求到後端
      final request = http.Request('POST', Uri.parse(ApiConfig.chatEndpoint));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'message': userMessage, 'history': history});

      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Backend error: ${response.statusCode}');
      }

      String fullContent = '';
      bool detectedTaskPlan = false;
      String displayContent = '';

      // 讀取 SSE 流
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            if (data == '[DONE]') {
              continue;
            }

            try {
              final json = jsonDecode(data);
              final chunkText = json['text'] as String? ?? '';
              fullContent += chunkText;

              // 檢查是否遇到任務計劃標記
              if (!detectedTaskPlan &&
                  fullContent.contains('[TASK_PLAN_READY]')) {
                detectedTaskPlan = true;
                displayContent = fullContent
                    .substring(0, fullContent.indexOf('[TASK_PLAN_READY]'))
                    .trim();

                final updatedMessages = state.messages.map((msg) {
                  if (msg.id == aiMessageId) {
                    return msg.copyWith(
                      content: displayContent,
                      isStreaming: true,
                    );
                  }
                  return msg;
                }).toList();

                state = state.copyWith(messages: updatedMessages);
                continue;
              }

              // 如果還沒遇到標記，逐字顯示
              if (!detectedTaskPlan) {
                for (int i = 0; i < chunkText.length; i++) {
                  displayContent += chunkText[i];

                  final updatedMessages = state.messages.map((msg) {
                    if (msg.id == aiMessageId) {
                      return msg.copyWith(
                        content: displayContent,
                        isStreaming: true,
                      );
                    }
                    return msg;
                  }).toList();

                  state = state.copyWith(messages: updatedMessages);
                  await Future.delayed(const Duration(milliseconds: 20));
                }
              }
            } catch (e) {
              // 忽略解析錯誤
            }
          }
        }
      }

      // 處理任務計劃
      TaskPlan? taskPlan;

      if (fullContent.contains('[TASK_PLAN_READY]')) {
        try {
          final startMarker = '[TASK_PLAN_READY]';
          final endMarker = '[/TASK_PLAN_READY]';
          final startIndex = fullContent.indexOf(startMarker);
          final endIndex = fullContent.indexOf(endMarker);

          if (startIndex != -1 && endIndex != -1) {
            final jsonStr = fullContent
                .substring(startIndex + startMarker.length, endIndex)
                .trim();

            final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
            taskPlan = TaskPlan.fromJson(jsonData);

            displayContent = fullContent.substring(0, startIndex).trim();
          }
        } catch (e) {
          debugPrint('Failed to parse task plan: $e');
        }
      }

      // 標記 streaming 結束
      final updatedMessages = state.messages.map((msg) {
        if (msg.id == aiMessageId) {
          return msg.copyWith(
            content: displayContent,
            isStreaming: false,
            taskPlan: taskPlan,
          );
        }
        return msg;
      }).toList();

      state = state.copyWith(messages: updatedMessages, isLoading: false);
      final finalMessage = updatedMessages.firstWhere(
        (msg) => msg.id == aiMessageId,
      );
      try {
        final activeSessionId = state.currentSessionId;
        if (activeSessionId != null) {
          await _db.insertChatMessage(finalMessage, sessionId: activeSessionId);
          await _db.touchChatSession(activeSessionId);
          await _reloadSessions(currentSessionId: activeSessionId);
        }
      } catch (e) {
        debugPrint('Failed to persist assistant message: $e');
      }
    } catch (e) {
      state = state.copyWith(
        error: '[AI_RESPONSE_FAILED]: $e',
        isLoading: false,
      );

      final updatedMessages = state.messages
          .where((msg) => msg.id != aiMessageId)
          .toList();

      state = state.copyWith(messages: updatedMessages);
    }
  }

  // 清空對話
  Future<void> clearChat() async {
    final activeSessionId = state.currentSessionId;
    if (activeSessionId == null) {
      return;
    }
    state = state.copyWith(messages: const []);
    try {
      await _db.clearChatMessagesBySession(activeSessionId);
      await _db.touchChatSession(activeSessionId);
      await _reloadSessions(currentSessionId: activeSessionId);
    } catch (e) {
      debugPrint('Failed to clear chat history: $e');
    }
  }

  // 清除錯誤訊息
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
