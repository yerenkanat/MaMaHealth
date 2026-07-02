import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/parenthood_repository.dart';
import '../../../domain/models/profile.dart';

part 'profile_switch_event.dart';
part 'profile_switch_state.dart';

/// Управляет списком профилей и активным контекстом (беременность/ребёнок).
class ProfileSwitchBloc extends Bloc<ProfileSwitchEvent, ProfileSwitchState> {
  ProfileSwitchBloc(this._repo) : super(const ProfileSwitchState()) {
    on<ProfilesRequested>(_onRequested);
    on<ProfileSelected>(_onSelected);
    on<ProfileStepChanged>(_onStepChanged);
    on<ChildAdded>(_onChildAdded);
  }

  final ParenthoodRepository _repo;

  Future<void> _onRequested(
    ProfilesRequested event,
    Emitter<ProfileSwitchState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profiles = await _repo.fetchProfiles();
      emit(state.copyWith(
        status: ProfileStatus.ready,
        profiles: profiles,
        activeProfileId: profiles.isNotEmpty ? profiles.first.id : null,
      ));
    } catch (err) {
      emit(state.copyWith(status: ProfileStatus.error, error: err.toString()));
    }
  }

  void _onSelected(ProfileSelected event, Emitter<ProfileSwitchState> emit) {
    emit(state.copyWith(activeProfileId: event.profileId));
  }

  void _onStepChanged(
    ProfileStepChanged event,
    Emitter<ProfileSwitchState> emit,
  ) {
    final active = state.activeProfile;
    if (active == null) return;
    final updated = [
      for (final p in state.profiles)
        p.id == active.id ? p.copyWith(currentStep: event.step) : p,
    ];
    emit(state.copyWith(profiles: updated));
  }

  Future<void> _onChildAdded(
    ChildAdded event,
    Emitter<ProfileSwitchState> emit,
  ) async {
    // После рождения перечитываем профили и делаем ребёнка активным.
    final profiles = await _repo.fetchProfiles();
    emit(state.copyWith(
      status: ProfileStatus.ready,
      profiles: profiles,
      activeProfileId: event.childId,
    ));
  }
}
