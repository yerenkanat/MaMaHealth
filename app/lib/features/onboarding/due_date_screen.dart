import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../engagement/engagement_service.dart';
import '../profile_switch/bloc/profile_switch_bloc.dart';

/// Онбординг/настройка: задать предполагаемую дату родов (ПДР).
/// Неделя беременности после сохранения пересчитывается на бэкенде.
class DueDateScreen extends StatefulWidget {
  const DueDateScreen({super.key});

  @override
  State<DueDateScreen> createState() => _DueDateScreenState();
}

class _DueDateScreenState extends State<DueDateScreen> {
  DateTime? _due;
  bool _saving = false;

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 60)),
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now.add(const Duration(days: 300)),
      helpText: 'Предполагаемая дата родов',
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (_due == null || _saving) return;
    final svc = context.read<EngagementService>();
    final bloc = context.read<ProfileSwitchBloc>();
    setState(() => _saving = true);
    try {
      await svc.setDueDate(_iso(_due!));
      bloc.add(const ProfilesRequested()); // пересчёт недели → обновить главную
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Срок сохранён — неделя обновлена')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить срок')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Срок беременности')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Укажите предполагаемую дату родов (ПДР).',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
                'Её ставит врач по УЗИ или по последней менструации. '
                'Неделя беременности в приложении пересчитается автоматически.',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 24),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pick,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Color(0xFF6A4BD0)),
                    const SizedBox(width: 12),
                    Text(
                      _due == null ? 'Выбрать дату' : _fmt(_due!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            _due == null ? FontWeight.w400 : FontWeight.w700,
                        color: _due == null ? AppColors.inkMuted : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _due == null || _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
