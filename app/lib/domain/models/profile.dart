import 'package:equatable/equatable.dart';

enum ProfileType { pregnancy, child }

/// Активный контекст на главном экране: беременность ИЛИ ребёнок.
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.type,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
  });

  final String id;
  final ProfileType type;
  final String title;     // «Беременность» | «Ерасыл»
  final int currentStep;  // индекс недели/месяца
  final int totalSteps;

  bool get isPregnancy => type == ProfileType.pregnancy;
  String get unitLabel => isPregnancy ? 'неделя' : 'месяц';

  Profile copyWith({int? currentStep}) => Profile(
        id: id,
        type: type,
        title: title,
        currentStep: currentStep ?? this.currentStep,
        totalSteps: totalSteps,
      );

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        type: (json['type'] as String) == 'PREGNANCY'
            ? ProfileType.pregnancy
            : ProfileType.child,
        title: json['title'] as String,
        currentStep: (json['currentStep'] as num).toInt(),
        totalSteps: (json['totalSteps'] as num).toInt(),
      );

  @override
  List<Object?> get props => [id, type, title, currentStep, totalSteps];
}
