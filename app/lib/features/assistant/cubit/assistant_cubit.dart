import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this._service)
      : super(const AssistantState(messages: [
          ChatMessage(ChatRole.assistant,
              'Здравствуйте! Я MaMa AI 💛 Спросите меня о беременности или развитии малыша.'),
        ]));

  final AssistantService _service;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    final withUser = [...state.messages, ChatMessage(ChatRole.user, trimmed)];
    emit(state.copyWith(messages: withUser, sending: true));

    final reply = await _service.reply(trimmed, withUser);
    emit(state.copyWith(
      messages: [...withUser, ChatMessage(ChatRole.assistant, reply)],
      sending: false,
    ));
  }
}
