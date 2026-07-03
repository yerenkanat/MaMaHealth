import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';
import '../assistant_service.dart';
import '../chat_message.dart';

class AssistantState extends Equatable {
  const AssistantState({this.messages = const [], this.sending = false});

  final List<ChatMessage> messages;
  final bool sending;

  AssistantState copyWith({List<ChatMessage>? messages, bool? sending}) =>
      AssistantState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
      );

  @override
  List<Object?> get props => [messages, sending];
}

const _greeting = ChatMessage(ChatRole.assistant,
    'Здравствуйте! Я MaMa AI 💛 Спросите меня о беременности или развитии малыша.');

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this._service, {EngagementService? engagement})
      : _engagement = engagement,
        super(const AssistantState(messages: [_greeting])) {
    _loadHistory();
  }

  final AssistantService _service;
  final EngagementService? _engagement;

  Future<void> _loadHistory() async {
    if (_engagement == null) return;
    try {
      final turns = await _engagement.chatHistory();
      if (turns.isEmpty) return;
      emit(state.copyWith(messages: [
        _greeting,
        for (final t in turns)
          ChatMessage(
            t.role == 'user' ? ChatRole.user : ChatRole.assistant,
            t.text,
          ),
      ]));
    } catch (_) {
      // офлайн — оставляем приветствие
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    final withUser = [...state.messages, ChatMessage(ChatRole.user, trimmed)];
    emit(state.copyWith(messages: withUser, sending: true));
    _persist('user', trimmed);

    final reply = await _service.reply(trimmed, withUser);
    emit(state.copyWith(
      messages: [...withUser, ChatMessage(ChatRole.assistant, reply)],
      sending: false,
    ));
    _persist('assistant', reply);
  }

  void _persist(String role, String text) {
    _engagement?.saveChatMessage(role, text).catchError((_) {});
  }
}
