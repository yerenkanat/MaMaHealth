import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth_gateway.dart';
import 'core/network/api_client.dart';
import 'core/network/token_store.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/api_parenthood_repository.dart';
import 'data/repositories/in_memory_parenthood_repository.dart';
import 'data/repositories/parenthood_repository.dart';
import 'features/birth_trigger/bloc/birth_trigger_bloc.dart';
import 'features/profile_switch/bloc/profile_switch_bloc.dart';
import 'features/shell/main_shell.dart';

/// Включить боевой API-режим: flutter run --dart-define=USE_API=true
/// (10.0.2.2 — хост-машина с точки зрения Android-эмулятора).
const bool _useApi = bool.fromEnvironment('USE_API');
const String _apiBaseUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ParenthoodRepository repository;
  if (_useApi) {
    final tokens = InMemoryTokenStore();
    final api = ApiClient(baseUrl: _apiBaseUrl, tokenStore: tokens);
    await AuthGateway(api, tokens).ensureSignedIn();
    repository = ApiParenthoodRepository(api);
  } else {
    repository = InMemoryParenthoodRepository();
  }

  runApp(MaMaApp(repository: repository));
}

class MaMaApp extends StatelessWidget {
  const MaMaApp({super.key, required this.repository});

  final ParenthoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                ProfileSwitchBloc(repository)..add(const ProfilesRequested()),
          ),
          BlocProvider(create: (_) => BirthTriggerBloc(repository)),
        ],
        child: MaterialApp(
          title: 'MaMa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pregnancy(),
          home: const MainShell(),
        ),
      ),
    );
  }
}
