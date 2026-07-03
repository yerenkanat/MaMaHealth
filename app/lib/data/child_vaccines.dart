/// Национальный календарь прививок РК (справочно, по возрасту ребёнка).
/// Данные ознакомительные — точные сроки уточняйте у педиатра.
class VaccineGroup {
  const VaccineGroup({
    required this.ageLabel,
    required this.ageMonths,
    required this.vaccines,
  });

  final String ageLabel; // напр. «2 месяца»
  final int ageMonths; // возраст в месяцах (для отметки «пройдено»)
  final List<String> vaccines;
}

class ChildVaccines {
  static const schedule = <VaccineGroup>[
    VaccineGroup(
      ageLabel: 'При рождении',
      ageMonths: 0,
      vaccines: ['Гепатит B (1 доза)', 'БЦЖ (туберкулёз)'],
    ),
    VaccineGroup(
      ageLabel: '2 месяца',
      ageMonths: 2,
      vaccines: [
        'Пентаксим (АКДС+ИПВ+ХИБ) — 1',
        'Пневмококковая — 1',
        'Ротавирусная — 1',
      ],
    ),
    VaccineGroup(
      ageLabel: '3 месяца',
      ageMonths: 3,
      vaccines: ['Пентаксим — 2', 'ОПВ (полиомиелит) — 1'],
    ),
    VaccineGroup(
      ageLabel: '4 месяца',
      ageMonths: 4,
      vaccines: [
        'Пентаксим — 3',
        'Пневмококковая — 2',
        'Ротавирусная — 2',
        'ОПВ — 2',
      ],
    ),
    VaccineGroup(
      ageLabel: '12–15 месяцев',
      ageMonths: 12,
      vaccines: ['КПК (корь, паротит, краснуха) — 1', 'Пневмококковая — ревакц.'],
    ),
    VaccineGroup(
      ageLabel: '18 месяцев',
      ageMonths: 18,
      vaccines: ['АКДС — ревакц.', 'ОПВ — 3', 'ХИБ — ревакц.'],
    ),
    VaccineGroup(
      ageLabel: '6 лет',
      ageMonths: 72,
      vaccines: ['КПК — 2', 'АДС (дифтерия, столбняк)'],
    ),
  ];
}
