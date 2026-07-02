import 'package:flutter/material.dart';

/// Справочник показателей УЗИ по скринингам (что означают аббревиатуры).
class UltrasoundScreen extends StatelessWidget {
  const UltrasoundScreen({super.key});

  static const _items = <(String, String, String)>[
    ('КТР', 'Копчико-теменной размер', 'Длина плода от темени до копчика (первый триместр).'),
    ('БПР', 'Бипариетальный размер', 'Ширина головки между теменными костями.'),
    ('ОГ', 'Окружность головы', 'Оценка роста и развития головного мозга.'),
    ('ОЖ', 'Окружность живота', 'Отражает питание и рост плода.'),
    ('ДБК', 'Длина бедренной кости', 'Помогает оценить срок и размеры.'),
    ('ТВП', 'Толщина воротникового пространства', 'Маркёр риска хромосомных аномалий (11–14 нед).'),
    ('ЧСС', 'Частота сердечных сокращений', 'Норма ~120–160 уд/мин.'),
    ('ИАЖ', 'Индекс амниотической жидкости', 'Оценка количества околоплодных вод.'),
    ('Плацента', 'Локализация и степень зрелости', 'Расположение и состояние плаценты.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расшифровка УЗИ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            elevation: 0,
            color: Color(0xFFFDF1D6),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Справочник основных показателей УЗИ. Точные нормы по вашему сроку '
                'определяет врач — значения зависят от недели беременности.',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final (abbr, full, desc) in _items)
            Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFDF1D6),
                  child: Text(abbr.length > 3 ? abbr.substring(0, 2) : abbr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                title: Text(full),
                subtitle: Text(desc),
              ),
            ),
        ],
      ),
    );
  }
}
