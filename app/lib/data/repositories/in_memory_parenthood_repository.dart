import '../../domain/models/new_child.dart';
import '../../domain/models/profile.dart';
import 'parenthood_repository.dart';

/// Демо-реализация без бэкенда — приложение запускается на эмуляторе сразу.
class InMemoryParenthoodRepository implements ParenthoodRepository {
  final List<Profile> _profiles = [
    const Profile(
      id: 'pg_001',
      type: ProfileType.pregnancy,
      title: 'Беременность',
      currentStep: 37, // 38-я неделя — кнопка «Я родила!» уже доступна
      totalSteps: 42,
    ),
    // Демо-ребёнок: включает переключатель профилей и режим роста.
    const Profile(
      id: 'ch_erasyl',
      type: ProfileType.child,
      title: 'Ерасыл',
      currentStep: 2, // 2 месяца
      totalSteps: 24,
      gender: 'male',
    ),
  ];
  int _seq = 0;

  @override
  Future<List<Profile>> fetchProfiles() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_profiles);
  }

  @override
  Future<String> triggerBirth({
    required String pregnancyId,
    required NewChild child,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = 'ch_${_seq++}';
    _profiles
      ..removeWhere((p) => p.id == pregnancyId)
      ..add(Profile(
        id: id,
        type: ProfileType.child,
        title: child.name,
        currentStep: 0,
        totalSteps: 24,
        gender: child.gender,
      ));
    return id;
  }
}
