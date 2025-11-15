import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import '../config/ai_config.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

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
  ChatNotifier() : super(ChatState()) {
    _initializeAI();
  }

  final _uuid = const Uuid();
  GenerativeModel? _model;
  ChatSession? _chatSession;

  void _initializeAI() {
    if (!AIConfig.isConfigured) {
      state = state.copyWith(error: '請先在 .env 文件中設置 GEMINI_API_KEY');
      return;
    }

    _model = GenerativeModel(
      model: AIConfig.modelName,
      apiKey: AIConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: AIConfig.temperature,
        maxOutputTokens: AIConfig.maxOutputTokens,
        topK: AIConfig.topK,
        topP: AIConfig.topP,
      ),
      systemInstruction: Content.system(AIConfig.systemPrompt),
    );

    _chatSession = _model!.startChat();
  }

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

  // 使用 Gemini API 生成 AI 回覆（支援 streaming）
  Future<void> generateAIResponse(String userMessage) async {
    if (_chatSession == null) {
      state = state.copyWith(error: 'AI 未初始化，請檢查 API Key 設置', isLoading: false);
      return;
    }

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
      // 使用 Gemini Streaming API
      final responseStream = _chatSession!.sendMessageStream(
        Content.text(userMessage),
      );

      String fullContent = '';
      bool detectedTaskPlan = false;
      String displayContent = '';

      // 逐字接收並顯示
      await for (final chunk in responseStream) {
        final chunkText = chunk.text ?? '';
        fullContent += chunkText;

        // 檢查是否遇到任務計劃標記
        if (!detectedTaskPlan && fullContent.contains('[TASK_PLAN_READY]')) {
          detectedTaskPlan = true;
          // 停止顯示文字，切換到 loading 狀態
          displayContent = fullContent
              .substring(0, fullContent.indexOf('[TASK_PLAN_READY]'))
              .trim();

          final updatedMessages = state.messages.map((msg) {
            if (msg.id == aiMessageId) {
              return msg.copyWith(
                content: displayContent,
                isStreaming: true, // 保持 streaming 狀態顯示 loading
              );
            }
            return msg;
          }).toList();

          state = state.copyWith(messages: updatedMessages);
          // 不要 break，繼續接收剩餘內容但不顯示
          continue;
        }

        // 如果還沒遇到標記，逐字顯示
        if (!detectedTaskPlan) {
          // 逐字顯示效果
          for (int i = 0; i < chunkText.length; i++) {
            displayContent += chunkText[i];

            final updatedMessages = state.messages.map((msg) {
              if (msg.id == aiMessageId) {
                return msg.copyWith(content: displayContent, isStreaming: true);
              }
              return msg;
            }).toList();

            state = state.copyWith(messages: updatedMessages);

            // 20ms 延遲，製造打字效果
            await Future.delayed(const Duration(milliseconds: 20));
          }
        }
      }

      // Stream 已經完全接收，處理最終內容

      // 檢查是否包含任務計劃標記
      TaskPlan? taskPlan;

      if (fullContent.contains('[TASK_PLAN_READY]')) {
        try {
          // 提取任務計劃 JSON
          final startMarker = '[TASK_PLAN_READY]';
          final endMarker = '[/TASK_PLAN_READY]';
          final startIndex = fullContent.indexOf(startMarker);
          final endIndex = fullContent.indexOf(endMarker);

          if (startIndex != -1 && endIndex != -1) {
            // 提取 JSON 字符串
            final jsonStr = fullContent
                .substring(startIndex + startMarker.length, endIndex)
                .trim();

            // 解析 JSON
            final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
            taskPlan = TaskPlan.fromJson(jsonData);

            // 更新 displayContent 為移除標記後的內容
            displayContent = fullContent.substring(0, startIndex).trim();
          }
        } catch (e) {
          // JSON 解析失敗，忽略任務計劃
          print('Failed to parse task plan: $e');
        }
      }

      // 標記 streaming 結束，並附加任務計劃
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
      // 錯誤處理
      state = state.copyWith(
        error: '[AI_RESPONSE_FAILED]: $e',
        isLoading: false,
      );

      // 移除失敗的訊息
      final updatedMessages = state.messages
          .where((msg) => msg.id != aiMessageId)
          .toList();

      state = state.copyWith(messages: updatedMessages);
    }
  }

  // 清空對話
  void clearChat() {
    state = ChatState();
    // 重新初始化 chat session，清除 API 端的對話歷史
    if (_model != null) {
      _chatSession = _model!.startChat();
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
