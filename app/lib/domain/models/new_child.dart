/// Данные новорождённого — payload триггера «Я родила!».
class NewChild {
  const NewChild({
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.birthWeightG,
    required this.birthHeightCm,
  });

  final String name;
  final String gender; // 'male' | 'female'
  final DateTime birthDate;
  final int birthWeightG;
  final double birthHeightCm;

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'birthDate': birthDate.toIso8601String(),
        'birthWeightG': birthWeightG,
        'birthHeightCm': birthHeightCm,
      };
}
