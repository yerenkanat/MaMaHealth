enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage(this.role, this.text);
  final ChatRole role;
  final String text;
}
