import 'package:flutter/material.dart';

/// Каталог имён с поиском и фильтром по полу.
class BabyNamesScreen extends StatefulWidget {
  const BabyNamesScreen({super.key});

  @override
  State<BabyNamesScreen> createState() => _BabyNamesScreenState();
}

class _Name {
  const _Name(this.name, this.gender, this.meaning);
  final String name;
  final String gender; // 'male' | 'female'
  final String meaning;
}

const _names = <_Name>[
  _Name('Ерасыл', 'male', 'благородный герой'),
  _Name('Алихан', 'male', 'великий правитель'),
  _Name('Нурлан', 'male', 'сияющий'),
  _Name('Арман', 'male', 'мечта'),
  _Name('Дамир', 'male', 'железный, крепкий'),
  _Name('Тимур', 'male', 'железо'),
  _Name('Санжар', 'male', 'пронзающий'),
  _Name('Ислам', 'male', 'покорность Богу'),
  _Name('Айсұлтан', 'male', 'лунный властитель'),
  _Name('Мансур', 'male', 'победоносный'),
  _Name('Аружан', 'female', 'красивая душа'),
  _Name('Аяжан', 'female', 'нежная, милая'),
  _Name('Мадина', 'female', 'название города'),
  _Name('Амина', 'female', 'верная, надёжная'),
  _Name('Дана', 'female', 'мудрая'),
  _Name('Дильназ', 'female', 'нежная душа'),
  _Name('Камила', 'female', 'совершенная'),
  _Name('Сафия', 'female', 'чистая, искренняя'),
  _Name('Аружан', 'female', 'прекрасная'),
  _Name('Зере', 'female', 'золотце'),
];

class _BabyNamesScreenState extends State<BabyNamesScreen> {
  final _search = TextEditingController();
  String _filter = 'all'; // all | male | female

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Name> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _names.where((n) {
      final byGender = _filter == 'all' || n.gender == _filter;
      final byQuery = q.isEmpty || n.name.toLowerCase().contains(q);
      return byGender && byQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор имени')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск имени',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('Все', 'all'),
                const SizedBox(width: 8),
                _chip('Мальчики', 'male'),
                const SizedBox(width: 8),
                _chip('Девочки', 'female'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = list[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: n.gender == 'male'
                        ? const Color(0xFFDCE6FA)
                        : const Color(0xFFFBE0EC),
                    child: Icon(
                        n.gender == 'male' ? Icons.male : Icons.female,
                        color: Colors.black54),
                  ),
                  title: Text(n.name),
                  subtitle: Text(n.meaning),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) => ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      );
}
