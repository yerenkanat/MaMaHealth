import 'network/api_client.dart';
import 'network/token_store.dart';

/// Демо-аутентификация для API-режима: логин, а при отсутствии пользователя —
/// регистрация. Полученный JWT сохраняется в [TokenStore] и далее шлётся
/// ApiClient'ом автоматически.
class AuthGateway {
  AuthGateway(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  static const _email = 'mom@mama.kz';
  static const _password = 'secret123';

  Future<void> ensureSignedIn() async {
    try {
      final res = await _api.post('/auth/login', {
        'email': _email,
        'password': _password,
      }) as Map<String, dynamic>;
      await _tokens.write(res['token'] as String);
    } on ApiException {
      final res = await _api.post('/auth/register', {
        'email': _email,
        'password': _password,
        'fullName': 'Айман',
        'districtId': 1,
      }) as Map<String, dynamic>;
      await _tokens.write(res['token'] as String);
    }
  }
}
