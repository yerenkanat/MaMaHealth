import 'package:flutter_test/flutter_test.dart';
import 'package:mama/data/repositories/in_memory_parenthood_repository.dart';
import 'package:mama/domain/models/new_child.dart';
import 'package:mama/features/birth_trigger/bloc/birth_trigger_bloc.dart';
import 'package:mama/features/profile_switch/bloc/profile_switch_bloc.dart';

void main() {
  test('ProfilesRequested загружает беременность и делает её активной', () async {
    final bloc = ProfileSwitchBloc(InMemoryParenthoodRepository());
    bloc.add(const ProfilesRequested());

    await expectLater(
      bloc.stream,
      emitsThrough(predicate<ProfileSwitchState>(
        (s) =>
            s.status == ProfileStatus.ready &&
            s.activeProfile?.isPregnancy == true,
      )),
    );
    await bloc.close();
  });

  test('BirthTrigger возвращает childId (success)', () async {
    final bloc = BirthTriggerBloc(InMemoryParenthoodRepository());
    bloc.add(BirthSubmitted(
      'pg_001',
      NewChild(
        name: 'Ерасыл',
        gender: 'male',
        birthDate: DateTime(2026, 5, 2),
        birthWeightG: 3400,
        birthHeightCm: 52,
      ),
    ));

    await expectLater(
      bloc.stream,
      emitsThrough(predicate<BirthTriggerState>(
        (s) => s.status == BirthStatus.success && s.childId != null,
      )),
    );
    await bloc.close();
  });
}
