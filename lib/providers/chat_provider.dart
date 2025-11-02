import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import '../models/task.dart';
import '../config/ai_config.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

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
      state = state.copyWith(
        error: '請先在 .env 文件中設置 GEMINI_API_KEY',
      );
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

    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  // 使用 Gemini API 生成 AI 回覆（支援 streaming）
  Future<void> generateAIResponse(String userMessage) async {
    if (_chatSession == null) {
      state = state.copyWith(
        error: 'AI 未初始化，請檢查 API Key 設置',
        isLoading: false,
      );
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

      // 逐字接收並顯示
      await for (final chunk in responseStream) {
        final chunkText = chunk.text ?? '';
        
        // 逐字顯示效果
        for (int i = 0; i < chunkText.length; i++) {
          fullContent += chunkText[i];
          
          // 更新訊息內容
          final updatedMessages = state.messages.map((msg) {
            if (msg.id == aiMessageId) {
              return msg.copyWith(
                content: fullContent,
                isStreaming: true,
              );
            }
            return msg;
          }).toList();

          state = state.copyWith(messages: updatedMessages);
          
          // 20ms 延遲，製造打字效果
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }

      // 標記 streaming 結束
      final updatedMessages = state.messages.map((msg) {
        if (msg.id == aiMessageId) {
          return msg.copyWith(
            content: fullContent,
            isStreaming: false,
          );
        }
        return msg;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
      );
    } catch (e) {
      // 錯誤處理
      state = state.copyWith(
        error: 'AI 回覆失敗: $e',
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
  }

  // 刪除特定訊息
  void deleteMessage(String messageId) {
    state = state.copyWith(
      messages: state.messages.where((msg) => msg.id != messageId).toList(),
    );
  }

  // 重試上一次失敗的請求
  Future<void> retryLastMessage() async {
    if (state.messages.isEmpty) return;

    final lastUserMessage = state.messages.lastWhere(
      (msg) => msg.role == MessageRole.user,
      orElse: () => state.messages.last,
    );

    if (lastUserMessage.role == MessageRole.user) {
      await generateAIResponse(lastUserMessage.content);
    }
  }

  // 從 AI 回覆中提取任務列表
  Future<List<Task>?> extractTasksFromLastResponse() async {
    if (state.messages.isEmpty) return null;

    // 找到最後一條 AI 訊息
    final lastAIMessage = state.messages.lastWhere(
      (msg) => msg.role == MessageRole.assistant,
      orElse: () => state.messages.last,
    );

    if (lastAIMessage.role != MessageRole.assistant) return null;

    try {
      // 使用新的模型實例來解析任務（避免干擾當前對話）
      final extractModel = GenerativeModel(
        model: AIConfig.modelName,
        apiKey: AIConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1, // 降低溫度以獲得更結構化的輸出
          maxOutputTokens: 2048,
        ),
      );

      final prompt = '''
請從以下內容中提取任務列表。每個任務應包含：
- title: 任務標題（簡短明確）
- description: 任務描述（詳細說明）
- pomodoroCount: 預估番茄鐘數量（1-8個）
- priority: 優先級（high/medium/low）

內容：
${lastAIMessage.content}

請以 JSON 格式返回任務列表，格式如下：
{
  "tasks": [
    {
      "title": "任務標題",
      "description": "任務描述",
      "pomodoroCount": 2,
      "priority": "medium"
    }
  ]
}

注意：
1. 只返回 JSON，不要有其他文字
2. 如果內容中沒有明確的任務，返回空列表：{"tasks": []}
3. 優先級判斷標準：high=緊急重要, medium=一般, low=可以延後
4. 番茄鐘數量：簡單任務1-2個，普通任務3-4個，複雜任務5-8個
''';

      final response = await extractModel.generateContent([
        Content.text(prompt),
      ]);

      final jsonText = response.text?.trim() ?? '';
      
      // 清理可能的 markdown 代碼塊標記
      String cleanedJson = jsonText;
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3);
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      // 解析 JSON
      final jsonData = jsonDecode(cleanedJson) as Map<String, dynamic>;
      final tasksList = jsonData['tasks'] as List<dynamic>;

      // 轉換為 Task 對象
      final tasks = tasksList.map((taskJson) {
        final taskMap = taskJson as Map<String, dynamic>;
        return Task(
          id: _uuid.v4(),
          title: taskMap['title'] as String,
          description: taskMap['description'] as String? ?? '',
          pomodoroCount: (taskMap['pomodoroCount'] as num?)?.toInt() ?? 2,
          priority: _parsePriority(taskMap['priority'] as String?),
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );
      }).toList();

      return tasks;
    } catch (e) {
      state = state.copyWith(
        error: '解析任務失敗: $e',
      );
      return null;
    }
  }

  TaskPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
