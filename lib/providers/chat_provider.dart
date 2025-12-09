import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../config/api_config.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({this.messages = const [], this.isLoading = false, this.error});

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState());

  final _uuid = const Uuid();

  // 添加用戶訊息
  void addUserMessage(String content) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, message]);
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
          print('Failed to parse task plan: $e');
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
  void clearChat() {
    state = ChatState();
  }

  // 清除錯誤訊息
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
