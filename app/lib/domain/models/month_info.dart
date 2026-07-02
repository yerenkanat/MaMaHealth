/// Контент календаря развития ребёнка на конкретный месяц.
class MonthInfo {
  const MonthInfo({
    required this.emoji,
    required this.stage,
    required this.milestone,
    required this.vaccination,
    required this.tip,
  });

  final String emoji;
  final String stage;        // «2 месяца»
  final String milestone;    // моторные/социальные навыки
  final String vaccination;  // прививки/осмотры
  final String tip;          // совет родителям
}
