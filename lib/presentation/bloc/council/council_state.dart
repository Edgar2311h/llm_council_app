import 'package:equatable/equatable.dart';
import '../../../domain/models/stage_result.dart';

/// Council query state
abstract class CouncilState extends Equatable {
  const CouncilState();

  @override
  List<Object?> get props => [];
}

class CouncilIdle extends CouncilState {}

class CouncilProcessing extends CouncilState {
  final bool stage1Loading;
  final bool stage2Loading;
  final bool stage3Loading;
  final List<ModelResponseResult>? stage1Results;
  final List<RankingResult>? stage2Results;
  final CouncilMetadata? metadata;
  final SynthesisResult? stage3Result;

  const CouncilProcessing({
    this.stage1Loading = false,
    this.stage2Loading = false,
    this.stage3Loading = false,
    this.stage1Results,
    this.stage2Results,
    this.metadata,
    this.stage3Result,
  });

  @override
  List<Object?> get props => [
        stage1Loading,
        stage2Loading,
        stage3Loading,
        stage1Results,
        stage2Results,
        metadata,
        stage3Result,
      ];

  CouncilProcessing copyWith({
    bool? stage1Loading,
    bool? stage2Loading,
    bool? stage3Loading,
    List<ModelResponseResult>? stage1Results,
    List<RankingResult>? stage2Results,
    CouncilMetadata? metadata,
    SynthesisResult? stage3Result,
  }) {
    return CouncilProcessing(
      stage1Loading: stage1Loading ?? this.stage1Loading,
      stage2Loading: stage2Loading ?? this.stage2Loading,
      stage3Loading: stage3Loading ?? this.stage3Loading,
      stage1Results: stage1Results ?? this.stage1Results,
      stage2Results: stage2Results ?? this.stage2Results,
      metadata: metadata ?? this.metadata,
      stage3Result: stage3Result ?? this.stage3Result,
    );
  }
}

class CouncilComplete extends CouncilState {
  final List<ModelResponseResult> stage1Results;
  final List<RankingResult> stage2Results;
  final SynthesisResult stage3Result;
  final CouncilMetadata metadata;
  final String? generatedTitle;

  const CouncilComplete({
    required this.stage1Results,
    required this.stage2Results,
    required this.stage3Result,
    required this.metadata,
    this.generatedTitle,
  });

  @override
  List<Object?> get props =>
      [stage1Results, stage2Results, stage3Result, metadata, generatedTitle];
}

class CouncilError extends CouncilState {
  final String message;

  const CouncilError(this.message);

  @override
  List<Object?> get props => [message];
}
