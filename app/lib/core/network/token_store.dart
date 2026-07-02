/// Хранилище JWT-токена.
///
/// В демо используется [InMemoryTokenStore] (без нативного кода).
/// Для продакшена подключить защищённое хранилище (Keychain/Keystore)
/// отдельной реализацией этого интерфейса — например, на базе
/// flutter_secure_storage или shared_preferences с шифрованием.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Простое хранилище в памяти (живёт в пределах сессии приложения).
class InMemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
