import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/growth_measurement.dart';

/// Хранит список замеров ребёнка; при добавлении заменяет замер того же
/// месяца и держит список отсортированным по возрасту.
class GrowthCubit extends Cubit<List<GrowthMeasurement>> {
  GrowthCubit([List<GrowthMeasurement>? seed]) : super(seed ?? const []);

  void add(GrowthMeasurement m) {
    final next = [
      ...state.where((e) => e.ageMonths != m.ageMonths),
      m,
    ]..sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
    emit(next);
  }
}
