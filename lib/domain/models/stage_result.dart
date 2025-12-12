import 'package:equatable/equatable.dart';

/// Represents a single model's response in Stage 1
class ModelResponseResult extends Equatable {
  final String model;
  final String response;

  const ModelResponseResult({
    required this.model,
    required this.response,
  });

  factory ModelResponseResult.fromJson(Map<String, dynamic> json) {
    return ModelResponseResult(
      model: json['model'] as String,
      response: json['response'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'response': response,
      };

  @override
  List<Object?> get props => [model, response];
}

/// Represents a model's ranking evaluation in Stage 2
class RankingResult extends Equatable {
  final String model;
  final String ranking; // Full text evaluation
  final List<String> parsedRanking; // Extracted ranking order

  const RankingResult({
    required this.model,
    required this.ranking,
    required this.parsedRanking,
  });

  factory RankingResult.fromJson(Map<String, dynamic> json) {
    return RankingResult(
      model: json['model'] as String,
      ranking: json['ranking'] as String,
      parsedRanking: (json['parsed_ranking'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'ranking': ranking,
        'parsed_ranking': parsedRanking,
      };

  @override
  List<Object?> get props => [model, ranking, parsedRanking];
}

/// Final synthesis from the chairman in Stage 3
class SynthesisResult extends Equatable {
  final String model;
  final String response;

  const SynthesisResult({
    required this.model,
    required this.response,
  });

  factory SynthesisResult.fromJson(Map<String, dynamic> json) {
    return SynthesisResult(
      model: json['model'] as String,
      response: json['response'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'response': response,
      };

  @override
  List<Object?> get props => [model, response];
}

/// Aggregate ranking statistics for a model
class AggregateRanking extends Equatable {
  final String model;
  final double averageRank;
  final int rankingsCount;

  const AggregateRanking({
    required this.model,
    required this.averageRank,
    required this.rankingsCount,
  });

  factory AggregateRanking.fromJson(Map<String, dynamic> json) {
    return AggregateRanking(
      model: json['model'] as String,
      averageRank: (json['average_rank'] as num).toDouble(),
      rankingsCount: json['rankings_count'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'average_rank': averageRank,
        'rankings_count': rankingsCount,
      };

  @override
  List<Object?> get props => [model, averageRank, rankingsCount];
}

/// Metadata for council response
class CouncilMetadata extends Equatable {
  final Map<String, String> labelToModel;
  final List<AggregateRanking> aggregateRankings;

  const CouncilMetadata({
    required this.labelToModel,
    required this.aggregateRankings,
  });

  factory CouncilMetadata.fromJson(Map<String, dynamic> json) {
    final labelMap = (json['label_to_model'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
    final rankings = (json['aggregate_rankings'] as List)
        .map((r) => AggregateRanking.fromJson(r))
        .toList();
    return CouncilMetadata(
      labelToModel: labelMap,
      aggregateRankings: rankings,
    );
  }

  Map<String, dynamic> toJson() => {
        'label_to_model': labelToModel,
        'aggregate_rankings': aggregateRankings.map((r) => r.toJson()).toList(),
      };

  @override
  List<Object?> get props => [labelToModel, aggregateRankings];
}

/// Complete council response containing all stages
class CouncilResponse extends Equatable {
  final List<ModelResponseResult> stage1;
  final List<RankingResult> stage2;
  final SynthesisResult stage3;
  final CouncilMetadata metadata;

  const CouncilResponse({
    required this.stage1,
    required this.stage2,
    required this.stage3,
    required this.metadata,
  });

  @override
  List<Object?> get props => [stage1, stage2, stage3, metadata];
}
