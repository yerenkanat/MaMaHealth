import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Единое состояние ошибки загрузки с кнопкой «Повторить».
/// Используется в ветках error у FutureBuilder-экранов.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    required this.onRetry,
    this.message = 'Не удалось загрузить данные',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.inkMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Проверьте соединение и попробуйте снова.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
