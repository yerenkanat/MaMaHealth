import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'assistant_service.dart';
import 'chat_message.dart';
import 'cubit/assistant_cubit.dart';

/// Вкладка MaMa AI — чат-ассистент (локальные ответы; позже — Claude API).
class MamaAiScreen extends StatelessWidget {
  const MamaAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AssistantCubit(context.read<AssistantService>()),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    context.read<AssistantCubit>().send(text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MaMa AI'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('умный помощник для мам',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AssistantCubit, AssistantState>(
              builder: (context, state) {
                final items = [
                  ...state.messages,
                  if (state.sending)
                    const ChatMessage(ChatRole.assistant, '…'),
                ];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _Bubble(message: items[i]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(context),
                      decoration: InputDecoration(
                        hintText: 'Спросите MaMa AI…',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: () => _send(context),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? scheme.primaryContainer : const Color(0xFFF1EEF7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text),
      ),
    );
  }
}
