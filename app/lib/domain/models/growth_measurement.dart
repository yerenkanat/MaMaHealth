/// Замер физического развития ребёнка на определённый возраст.
class GrowthMeasurement {
  const GrowthMeasurement({
    required this.ageMonths,
    required this.weightKg,
    required this.heightCm,
  });

  final int ageMonths;
  final double weightKg;
  final double heightCm;
}
