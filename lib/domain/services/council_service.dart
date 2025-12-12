import 'dart:async';
import '../../data/api/openrouter_client.dart';
import '../models/stage_result.dart';
import 'ranking_parser.dart';

/// Council stage update types for streaming
enum CouncilStage {
  stage1Start,
  stage1Complete,
  stage2Start,
  stage2Complete,
  stage3Start,
  stage3Complete,
  titleComplete,
  error,
}

/// Update event for council progress
class CouncilUpdate {
  final CouncilStage stage;
  final dynamic data;
  final String? error;

  CouncilUpdate({
    required this.stage,
    this.data,
    this.error,
  });
}

/// Core council orchestration service.
/// Ports the 3-stage LLM council logic from Python to Dart.
class CouncilService {
  final OpenRouterClient _client;
  final List<String> _councilModels;
  final String _chairmanModel;

  CouncilService({
    required OpenRouterClient client,
    required List<String> councilModels,
    required String chairmanModel,
  })  : _client = client,
        _councilModels = councilModels,
        _chairmanModel = chairmanModel;

  /// Run the complete 3-stage council process with streaming updates
  Stream<CouncilUpdate> runCouncilStream(String userQuery) async* {
    try {
      // Stage 1: Collect individual responses
      print(
          '[CouncilService] Starting Stage 1: Collecting responses from ${_councilModels.length} models');
      yield CouncilUpdate(stage: CouncilStage.stage1Start);

      final stage1Results = await _stage1CollectResponses(userQuery);

      print(
          '[CouncilService] Stage 1 complete: Got ${stage1Results.length} responses');

      if (stage1Results.isEmpty) {
        print('[CouncilService] ERROR: All models failed to respond');
        yield CouncilUpdate(
          stage: CouncilStage.error,
          error:
              'All models failed to respond. Please check your API key and model availability.',
        );
        return;
      }

      yield CouncilUpdate(
        stage: CouncilStage.stage1Complete,
        data: stage1Results,
      );

      // Stage 2: Collect rankings
      print('[CouncilService] Starting Stage 2: Collecting peer rankings');
      yield CouncilUpdate(stage: CouncilStage.stage2Start);

      final (stage2Results, labelToModel) = await _stage2CollectRankings(
        userQuery,
        stage1Results,
      );

      print(
          '[CouncilService] Stage 2 complete: Got ${stage2Results.length} rankings');

      final aggregateRankings = _calculateAggregateRankings(
        stage2Results,
        labelToModel,
      );

      final metadata = CouncilMetadata(
        labelToModel: labelToModel,
        aggregateRankings: aggregateRankings,
      );

      yield CouncilUpdate(
        stage: CouncilStage.stage2Complete,
        data: {'results': stage2Results, 'metadata': metadata},
      );

      // Stage 3: Synthesize final answer
      print(
          '[CouncilService] Starting Stage 3: Chairman synthesis with $_chairmanModel');
      yield CouncilUpdate(stage: CouncilStage.stage3Start);

      final stage3Result = await _stage3SynthesizeFinal(
        userQuery,
        stage1Results,
        stage2Results,
      );

      print('[CouncilService] Stage 3 complete: Got synthesis response');

      yield CouncilUpdate(
        stage: CouncilStage.stage3Complete,
        data: stage3Result,
      );

      // Generate title
      print('[CouncilService] Generating conversation title');
      final title = await _generateConversationTitle(userQuery);
      print('[CouncilService] Title generated: $title');
      yield CouncilUpdate(
        stage: CouncilStage.titleComplete,
        data: title,
      );
    } on RateLimitException catch (e) {
      print('[CouncilService] Rate limit error: $e');
      yield CouncilUpdate(
        stage: CouncilStage.error,
        error:
            '⏱️ Rate Limited\n\nThe free models are temporarily rate limited. Please:\n• Wait 1-2 minutes and try again\n• Or switch to Premium/Speed preset in Settings\n• Or reduce the number of council models',
      );
    } on ModelNotFoundException catch (e) {
      print('[CouncilService] Model not found: $e');
      yield CouncilUpdate(
        stage: CouncilStage.error,
        error:
            '❌ Model Unavailable\n\nThe model "${e.model}" is not available. Please go to Settings and select different models.',
      );
    } on AuthorizationException catch (e) {
      print('[CouncilService] Auth error: $e');
      yield CouncilUpdate(
        stage: CouncilStage.error,
        error:
            '🔑 API Key Error\n\nYour API key doesn\'t have access to this model. Please check your OpenRouter API key in Settings.',
      );
    } catch (e, stackTrace) {
      print('[CouncilService] ERROR: $e');
      print('[CouncilService] Stack trace: $stackTrace');
      yield CouncilUpdate(
        stage: CouncilStage.error,
        error: 'Council error: $e',
      );
    }
  }

  /// Stage 1: Collect individual responses from all council models
  Future<List<ModelResponseResult>> _stage1CollectResponses(
      String userQuery) async {
    final messages = [
      {'role': 'user', 'content': userQuery}
    ];

    final responses = await _client.queryModelsParallel(
      models: _councilModels,
      messages: messages,
    );

    final results = <ModelResponseResult>[];
    for (final entry in responses.entries) {
      if (entry.value != null) {
        results.add(ModelResponseResult(
          model: entry.key,
          response: entry.value!.content,
        ));
      }
    }

    return results;
  }

  /// Stage 2: Each model ranks the anonymized responses
  Future<(List<RankingResult>, Map<String, String>)> _stage2CollectRankings(
    String userQuery,
    List<ModelResponseResult> stage1Results,
  ) async {
    // Create anonymized labels
    final labels = RankingParser.getLabels(stage1Results.length);

    // Create mapping from label to model name
    final labelToModel = <String, String>{};
    for (var i = 0; i < stage1Results.length; i++) {
      labelToModel['Response ${labels[i]}'] = stage1Results[i].model;
    }

    // Build responses text
    final responsesText = StringBuffer();
    for (var i = 0; i < stage1Results.length; i++) {
      responsesText.writeln('Response ${labels[i]}:');
      responsesText.writeln(stage1Results[i].response);
      responsesText.writeln();
    }

    final rankingPrompt =
        '''You are evaluating different responses to the following question:

Question: $userQuery

Here are the responses from different models (anonymized):

$responsesText

Your task:
1. First, evaluate each response individually. For each response, explain what it does well and what it does poorly.
2. Then, at the very end of your response, provide a final ranking.

IMPORTANT: Your final ranking MUST be formatted EXACTLY as follows:
- Start with the line "FINAL RANKING:" (all caps, with colon)
- Then list the responses from best to worst as a numbered list
- Each line should be: number, period, space, then ONLY the response label (e.g., "1. Response A")
- Do not add any other text or explanations in the ranking section

Example of the correct format for your ENTIRE response:

Response A provides good detail on X but misses Y...
Response B is accurate but lacks depth on Z...
Response C offers the most comprehensive answer...

FINAL RANKING:
1. Response C
2. Response A
3. Response B

Now provide your evaluation and ranking:''';

    final messages = [
      {'role': 'user', 'content': rankingPrompt}
    ];

    final responses = await _client.queryModelsParallel(
      models: _councilModels,
      messages: messages,
    );

    final results = <RankingResult>[];
    for (final entry in responses.entries) {
      if (entry.value != null) {
        final fullText = entry.value!.content;
        final parsed = RankingParser.parseRankingFromText(fullText);

        results.add(RankingResult(
          model: entry.key,
          ranking: fullText,
          parsedRanking: parsed,
        ));
      }
    }

    return (results, labelToModel);
  }

  /// Stage 3: Chairman synthesizes final response
  Future<SynthesisResult> _stage3SynthesizeFinal(
    String userQuery,
    List<ModelResponseResult> stage1Results,
    List<RankingResult> stage2Results,
  ) async {
    // Build comprehensive context for chairman
    final stage1Text = StringBuffer();
    for (final result in stage1Results) {
      stage1Text.writeln('Model: ${result.model}');
      stage1Text.writeln('Response: ${result.response}');
      stage1Text.writeln();
    }

    final stage2Text = StringBuffer();
    for (final result in stage2Results) {
      stage2Text.writeln('Model: ${result.model}');
      stage2Text.writeln('Ranking: ${result.ranking}');
      stage2Text.writeln();
    }

    final chairmanPrompt =
        '''You are the Chairman of an LLM Council. Multiple AI models have provided responses to a user's question, and then ranked each other's responses.

Original Question: $userQuery

STAGE 1 - Individual Responses:
$stage1Text

STAGE 2 - Peer Rankings:
$stage2Text

Your task as Chairman is to synthesize all of this information into a single, comprehensive, accurate answer to the user's original question. Consider:
- The individual responses and their insights
- The peer rankings and what they reveal about response quality
- Any patterns of agreement or disagreement

Provide a clear, well-reasoned final answer that represents the council's collective wisdom:''';

    final messages = [
      {'role': 'user', 'content': chairmanPrompt}
    ];

    final response = await _client.queryModel(
      model: _chairmanModel,
      messages: messages,
    );

    if (response == null) {
      return SynthesisResult(
        model: _chairmanModel,
        response: 'Error: Unable to generate final synthesis.',
      );
    }

    return SynthesisResult(
      model: _chairmanModel,
      response: response.content,
    );
  }

  /// Calculate aggregate rankings across all models
  List<AggregateRanking> _calculateAggregateRankings(
    List<RankingResult> stage2Results,
    Map<String, String> labelToModel,
  ) {
    final modelPositions = <String, List<int>>{};

    for (final ranking in stage2Results) {
      final parsedRanking = ranking.parsedRanking;

      for (var position = 0; position < parsedRanking.length; position++) {
        final label = parsedRanking[position];
        if (labelToModel.containsKey(label)) {
          final modelName = labelToModel[label]!;
          modelPositions.putIfAbsent(modelName, () => []);
          modelPositions[modelName]!.add(position + 1);
        }
      }
    }

    final aggregate = <AggregateRanking>[];
    for (final entry in modelPositions.entries) {
      if (entry.value.isNotEmpty) {
        final avgRank =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
        aggregate.add(AggregateRanking(
          model: entry.key,
          averageRank: double.parse(avgRank.toStringAsFixed(2)),
          rankingsCount: entry.value.length,
        ));
      }
    }

    // Sort by average rank (lower is better)
    aggregate.sort((a, b) => a.averageRank.compareTo(b.averageRank));

    return aggregate;
  }

  /// Generate a short title for the conversation
  Future<String> _generateConversationTitle(String userQuery) async {
    final titlePrompt =
        '''Generate a very short title (3-5 words maximum) that summarizes the following question.
The title should be concise and descriptive. Do not use quotes or punctuation in the title.

Question: $userQuery

Title:''';

    final messages = [
      {'role': 'user', 'content': titlePrompt}
    ];

    final response = await _client.queryModel(
      model: _chairmanModel,
      messages: messages,
      timeout: const Duration(seconds: 30),
    );

    if (response == null) {
      return 'New Conversation';
    }

    var title = response.content.trim();

    // Clean up the title - remove leading/trailing quotes
    title = title
        .replaceAll(RegExp(r'^["]+|["]+$'), '')
        .replaceAll(RegExp(r"^'+|'+$"), '');

    // Truncate if too long
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }

    return title.isEmpty ? 'New Conversation' : title;
  }
}
