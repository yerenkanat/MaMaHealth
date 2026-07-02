import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/parenthood_repository.dart';
import '../../../domain/models/new_child.dart';

part 'birth_trigger_event.dart';
part 'birth_trigger_state.dart';

/// Обрабатывает миграцию «беременность → ребёнок» по кнопке «Я родила!».
class BirthTriggerBloc extends Bloc<BirthTriggerEvent, BirthTriggerState> {
  BirthTriggerBloc(this._repo) : super(const BirthTriggerState()) {
    on<BirthSubmitted>(_onSubmitted);
  }

  final ParenthoodRepository _repo;

  Future<void> _onSubmitted(
    BirthSubmitted event,
    Emitter<BirthTriggerState> emit,
  ) async {
    emit(state.copyWith(status: BirthStatus.submitting));
    try {
      final childId = await _repo.triggerBirth(
        pregnancyId: event.pregnancyId,
        child: event.child,
      );
      emit(state.copyWith(status: BirthStatus.success, childId: childId));
    } catch (err) {
      emit(state.copyWith(status: BirthStatus.failure, error: err.toString()));
    }
  }
}
