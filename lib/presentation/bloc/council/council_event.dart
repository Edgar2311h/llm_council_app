import 'package:equatable/equatable.dart';

/// Council events
abstract class CouncilEvent extends Equatable {
  const CouncilEvent();

  @override
  List<Object?> get props => [];
}

class SubmitQuery extends CouncilEvent {
  final String conversationId;
  final String query;

  const SubmitQuery({
    required this.conversationId,
    required this.query,
  });

  @override
  List<Object?> get props => [conversationId, query];
}

class ResetCouncil extends CouncilEvent {}
