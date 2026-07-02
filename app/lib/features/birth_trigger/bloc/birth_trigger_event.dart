part of 'birth_trigger_bloc.dart';

sealed class BirthTriggerEvent extends Equatable {
  const BirthTriggerEvent();
  @override
  List<Object?> get props => [];
}

/// Отправить данные новорождённого и запустить миграцию.
class BirthSubmitted extends BirthTriggerEvent {
  const BirthSubmitted(this.pregnancyId, this.child);
  final String pregnancyId;
  final NewChild child;
  @override
  List<Object?> get props => [pregnancyId, child.name, child.birthDate];
}
