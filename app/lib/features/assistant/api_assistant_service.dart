import '../../core/network/api_client.dart';
import 'assistant_service.dart';
import 'chat_message.dart';

/// Ассистент через backend `/assistant/chat` (реальный Claude или локальный фолбэк).
class ApiAssistantService implements AssistantService {
  ApiAssistantService(this._api);
  final ApiClient _api;

  @override
  Future<String> reply(String userMessage, List<ChatMessage> history) async {
    final res = await _api.post('/assistant/chat', {
      'messages': [
        for (final m in history)
          {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'text': m.text,
          },
      ],
    }) as Map<String, dynamic>;
    return res['reply'] as String;
  }
}
