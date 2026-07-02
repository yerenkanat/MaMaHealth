part of 'profile_switch_bloc.dart';

sealed class ProfileSwitchEvent extends Equatable {
  const ProfileSwitchEvent();
  @override
  List<Object?> get props => [];
}

/// Загрузить профили пользователя.
class ProfilesRequested extends ProfileSwitchEvent {
  const ProfilesRequested();
}

/// Переключить активный профиль.
class ProfileSelected extends ProfileSwitchEvent {
  const ProfileSelected(this.profileId);
  final String profileId;
  @override
  List<Object?> get props => [profileId];
}

/// Пользователь проскроллил таймлайн на другой шаг.
class ProfileStepChanged extends ProfileSwitchEvent {
  const ProfileStepChanged(this.step);
  final int step;
  @override
  List<Object?> get props => [step];
}

/// Родился ребёнок — подхватить его как активный профиль.
class ChildAdded extends ProfileSwitchEvent {
  const ChildAdded(this.childId);
  final String childId;
  @override
  List<Object?> get props => [childId];
}
