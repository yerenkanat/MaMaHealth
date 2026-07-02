/// Понедельная справочная информация о беременности.
class WeekInfo {
  const WeekInfo({
    required this.week,
    required this.fruit,
    required this.emoji,
    required this.lengthCm,
    required this.weight,
    required this.aboutBaby,
    required this.aboutYou,
    required this.tip,
  });

  final int week;
  final String fruit;    // сравнение размера: «Слива»
  final String emoji;    // эмодзи-иконка фрукта
  final String lengthCm; // рост: «2–3 см»
  final String weight;   // вес: «4 г»
  final String aboutBaby;
  final String aboutYou;
  final String tip;
}
