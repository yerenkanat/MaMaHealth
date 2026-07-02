part of 'birth_trigger_bloc.dart';

enum BirthStatus { idle, submitting, success, failure }

class BirthTriggerState extends Equatable {
  const BirthTriggerState({
    this.status = BirthStatus.idle,
    this.childId,
    this.error,
  });

  final BirthStatus status;
  final String? childId;
  final String? error;

  BirthTriggerState copyWith({
    BirthStatus? status,
    String? childId,
    String? error,
  }) {
    return BirthTriggerState(
      status: status ?? this.status,
      childId: childId ?? this.childId,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, childId, error];
}
