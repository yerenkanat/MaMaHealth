import '../../core/network/api_client.dart';
import '../../domain/models/new_child.dart';
import '../../domain/models/profile.dart';
import 'parenthood_repository.dart';

/// Боевая реализация — ходит в бэкенд (api/).
class ApiParenthoodRepository implements ParenthoodRepository {
  ApiParenthoodRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Profile>> fetchProfiles() async {
    final data = await _api.get('/profiles') as List<dynamic>;
    return data
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> triggerBirth({
    required String pregnancyId,
    required NewChild child,
  }) async {
    final res = await _api.post(
      '/pregnancies/$pregnancyId/birth',
      child.toJson(),
    ) as Map<String, dynamic>;
    return res['childId'] as String;
  }
}
