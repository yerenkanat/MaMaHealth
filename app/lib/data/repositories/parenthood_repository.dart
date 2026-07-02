import '../../domain/models/new_child.dart';
import '../../domain/models/profile.dart';

/// Контракт слоя данных «непрерывного родительства».
abstract interface class ParenthoodRepository {
  Future<List<Profile>> fetchProfiles();

  /// Триггер «Я родила!» — возвращает id профиля новорождённого.
  Future<String> triggerBirth({
    required String pregnancyId,
    required NewChild child,
  });
}
