import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/api/openrouter_client.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/storage/secure_storage_service.dart';
import '../../../domain/models/stage_result.dart';
import '../../../domain/services/council_service.dart';
import '../../../core/constants.dart';
import '../conversation/conversation_bloc.dart';
import '../conversation/conversation_event.dart';
import 'council_event.dart';
import 'council_state.dart';

class CouncilBloc extends Bloc<CouncilEvent, CouncilState> {
  final SecureStorageService _secureStorage;
  final DatabaseHelper _database;
  final ConversationBloc _conversationBloc;

  StreamSubscription<CouncilUpdate>? _councilSubscription;

  CouncilBloc({
    required ConversationBloc conversationBloc,
    SecureStorageService? secureStorage,
    DatabaseHelper? database,
  })  : _secureStorage = secureStorage ?? SecureStorageService.instance,
        _database = database ?? DatabaseHelper.instance,
        _conversationBloc = conversationBloc,
        super(CouncilIdle()) {
    on<SubmitQuery>(_onSubmitQuery);
    on<ResetCouncil>(_onResetCouncil);
  }

  Future<void> _onSubmitQuery(
    SubmitQuery event,
    Emitter<CouncilState> emit,
  ) async {
    // Cancel any existing subscription
    await _councilSubscription?.cancel();

    try {
      // Get API key
      final apiKey = await _secureStorage.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        emit(const CouncilError(
            'API key not configured. Please add your OpenRouter API key in settings.'));
        return;
      }
      print('[Council] API key found: ${apiKey.substring(0, 10)}...');

      // Get settings
      final councilModelsJson =
          await _database.getSetting(StorageKeys.councilModels);
      final chairmanModel =
          await _database.getSetting(StorageKeys.chairmanModel);

      print('[Council] Raw councilModelsJson: $councilModelsJson');
      print('[Council] Raw chairmanModel: $chairmanModel');

      List<String> councilModels = CouncilDefaults.councilModels;
      if (councilModelsJson != null && councilModelsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(councilModelsJson);
          if (decoded is List) {
            councilModels = decoded.cast<String>();
          }
        } catch (e) {
          print('[Council] Failed to parse council models JSON: $e');
          // Use defaults if parsing fails
        }
      }

      print('[Council] Using council models: $councilModels');
      print(
          '[Council] Using chairman: ${chairmanModel ?? CouncilDefaults.chairmanModel}');

      // Add user message to database first
      await _database.addUserMessage(event.conversationId, event.query);
      _conversationBloc.add(RefreshMessages(event.conversationId));

      // Create council service
      final client = OpenRouterClient(apiKey: apiKey);
      final councilService = CouncilService(
        client: client,
        councilModels: councilModels,
        chairmanModel: chairmanModel ?? CouncilDefaults.chairmanModel,
      );

      print(
          '[Council] Starting council stream for query: "${event.query.substring(0, event.query.length.clamp(0, 50))}..."');

      // Track results as they come in
      List<ModelResponseResult>? stage1Results;
      List<RankingResult>? stage2Results;
      CouncilMetadata? metadata;
      SynthesisResult? stage3Result;
      String? generatedTitle;

      // Process streaming updates
      await for (final update in councilService.runCouncilStream(event.query)) {
        switch (update.stage) {
          case CouncilStage.stage1Start:
            emit(const CouncilProcessing(stage1Loading: true));
            break;

          case CouncilStage.stage1Complete:
            stage1Results = update.data as List<ModelResponseResult>;
            emit(CouncilProcessing(
              stage1Results: stage1Results,
            ));
            break;

          case CouncilStage.stage2Start:
            emit(CouncilProcessing(
              stage1Results: stage1Results,
              stage2Loading: true,
            ));
            break;

          case CouncilStage.stage2Complete:
            final data = update.data as Map<String, dynamic>;
            stage2Results = data['results'] as List<RankingResult>;
            metadata = data['metadata'] as CouncilMetadata;
            emit(CouncilProcessing(
              stage1Results: stage1Results,
              stage2Results: stage2Results,
              metadata: metadata,
            ));
            break;

          case CouncilStage.stage3Start:
            emit(CouncilProcessing(
              stage1Results: stage1Results,
              stage2Results: stage2Results,
              metadata: metadata,
              stage3Loading: true,
            ));
            break;

          case CouncilStage.stage3Complete:
            stage3Result = update.data as SynthesisResult;
            emit(CouncilProcessing(
              stage1Results: stage1Results,
              stage2Results: stage2Results,
              metadata: metadata,
              stage3Result: stage3Result,
            ));
            break;

          case CouncilStage.titleComplete:
            generatedTitle = update.data as String;

            // Save assistant message to database
            if (stage1Results != null &&
                stage2Results != null &&
                stage3Result != null &&
                metadata != null) {
              await _database.addAssistantMessage(
                conversationId: event.conversationId,
                stage1: stage1Results,
                stage2: stage2Results,
                stage3: stage3Result,
                metadata: metadata,
              );

              // Only update title if it's still the default "New Conversation"
              // Don't overwrite if user has manually edited it
              final currentConversation =
                  await _database.getConversation(event.conversationId);
              if (currentConversation != null &&
                  currentConversation.title == 'New Conversation') {
                await _database.updateConversationTitle(
                  event.conversationId,
                  generatedTitle,
                );
              }

              // Refresh messages only - don't call LoadConversations
              // as it triggers navigation in home screen
              _conversationBloc.add(RefreshMessages(event.conversationId));

              emit(CouncilComplete(
                stage1Results: stage1Results,
                stage2Results: stage2Results,
                stage3Result: stage3Result,
                metadata: metadata,
                generatedTitle: generatedTitle,
              ));
            }
            break;

          case CouncilStage.error:
            emit(CouncilError(update.error ?? 'Unknown error occurred'));
            break;
        }
      }
    } catch (e) {
      emit(CouncilError(e.toString()));
    }
  }

  void _onResetCouncil(
    ResetCouncil event,
    Emitter<CouncilState> emit,
  ) {
    _councilSubscription?.cancel();
    emit(CouncilIdle());
  }

  @override
  Future<void> close() {
    _councilSubscription?.cancel();
    return super.close();
  }
}
