import 'package:flutter/material.dart';

/// Справочник «Что можно есть» / «Что можно делать» — списки «можно» и «избегать».
class AllowedScreen extends StatelessWidget {
  const AllowedScreen({super.key, required this.title, required this.kind});

  final String title;
  final String kind; // 'food' | 'activity'

  static const _food = (
    can: [
      'Овощи и фрукты (мытые)',
      'Нежирное мясо и птица (хорошо прожаренные)',
      'Рыба с низким содержанием ртути',
      'Молочные продукты (пастеризованные)',
      'Цельные злаки, бобовые',
      'Достаточно воды',
    ],
    avoid: [
      'Сырые/непрожаренные мясо и рыба',
      'Непастеризованные молочные продукты',
      'Сырые яйца',
      'Алкоголь',
      'Избыток кофеина',
      'Рыба с высоким содержанием ртути',
    ],
  );

  static const _activity = (
    can: [
      'Прогулки на свежем воздухе',
      'Плавание и аквааэробика',
      'Йога и растяжка для беременных',
      'Лёгкая гимнастика',
      'Дыхательные упражнения',
    ],
    avoid: [
      'Поднятие тяжестей',
      'Контактный и травмоопасный спорт',
      'Горячая ванна / сауна',
      'Курение и пассивное курение',
      'Длительное стояние без отдыха',
    ],
  );

  @override
  Widget build(BuildContext context) {
    final data = kind == 'activity' ? _activity : _food;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _block('Можно', data.can, const Color(0xFFDDF3E4), Icons.check_circle, Colors.green),
          const SizedBox(height: 16),
          _block('Лучше избегать', data.avoid, const Color(0xFFFDE0E0), Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _block(String heading, List<String> items, Color bg, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(it)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
