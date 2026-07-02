part of 'profile_switch_bloc.dart';

enum ProfileStatus { initial, loading, ready, error }

class ProfileSwitchState extends Equatable {
  const ProfileSwitchState({
    this.status = ProfileStatus.initial,
    this.profiles = const [],
    this.activeProfileId,
    this.error,
  });

  final ProfileStatus status;
  final List<Profile> profiles;
  final String? activeProfileId;
  final String? error;

  /// Активный профиль (или первый доступный как fallback).
  Profile? get activeProfile {
    for (final p in profiles) {
      if (p.id == activeProfileId) return p;
    }
    return profiles.isNotEmpty ? profiles.first : null;
  }

  ProfileSwitchState copyWith({
    ProfileStatus? status,
    List<Profile>? profiles,
    String? activeProfileId,
    String? error,
  }) {
    return ProfileSwitchState(
      status: status ?? this.status,
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, profiles, activeProfileId, error];
}
