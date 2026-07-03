import 'package:flutter/material.dart';

/// Калькулятор возможной группы крови ребёнка по группам родителей + резус.
class BloodTypeScreen extends StatefulWidget {
  const BloodTypeScreen({super.key});

  @override
  State<BloodTypeScreen> createState() => _BloodTypeScreenState();
}

class _BloodTypeScreenState extends State<BloodTypeScreen> {
  String _mother = 'O';
  String _father = 'O';
  bool _motherRhPlus = true;
  bool _fatherRhPlus = true;

  static const _groups = ['O', 'A', 'B', 'AB'];

  // Аллели-гаметы, которые может передать группа.
  List<String> _alleles(String g) => switch (g) {
        'O' => ['O'],
        'A' => ['A', 'O'],
        'B' => ['B', 'O'],
        'AB' => ['A', 'B'],
        _ => ['O'],
      };

  String _phenotype(String a, String b) {
    final set = {a, b};
    if (set.contains('A') && set.contains('B')) return 'AB';
    if (set.contains('A')) return 'A';
    if (set.contains('B')) return 'B';
    return 'O';
  }

  Set<String> get _possibleGroups {
    final res = <String>{};
    for (final a in _alleles(_mother)) {
      for (final b in _alleles(_father)) {
        res.add(_phenotype(a, b));
      }
    }
    return res;
  }

  bool get _rhConflictRisk => !_motherRhPlus && _fatherRhPlus;

  @override
  Widget build(BuildContext context) {
    final groups = _possibleGroups.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Группа крови младенца')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _parentSelector(
            'Мама',
            _mother,
            _motherRhPlus,
            (g) => setState(() => _mother = g),
            (rh) => setState(() => _motherRhPlus = rh),
          ),
          const SizedBox(height: 12),
          _parentSelector(
            'Папа',
            _father,
            _fatherRhPlus,
            (g) => setState(() => _father = g),
            (rh) => setState(() => _fatherRhPlus = rh),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: const Color(0xFFF3EFFA),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Возможные группы крови ребёнка',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final g in groups)
                        Chip(label: Text(g, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Резус ребёнка: ${(_motherRhPlus || _fatherRhPlus) ? 'может быть + или −' : 'скорее всего −'}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          if (_rhConflictRisk) ...[
            const SizedBox(height: 12),
            const Card(
              elevation: 0,
              color: Color(0xFFFDE0E6),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.warning_amber, color: Color(0xFFD53A5E)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Возможен резус-конфликт (мама Rh−, папа Rh+). '
                      'Обсудите с врачом наблюдение и профилактику.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _parentSelector(
    String label,
    String group,
    bool rhPlus,
    ValueChanged<String> onGroup,
    ValueChanged<bool> onRh,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final g in _groups)
                        ChoiceChip(
                          label: Text(g),
                          selected: group == g,
                          onSelected: (_) => onGroup(g),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [rhPlus, !rhPlus],
                  onPressed: (i) => onRh(i == 0),
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                  children: const [Text('Rh+'), Text('Rh−')],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
