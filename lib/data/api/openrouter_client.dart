import 'package:dio/dio.dart';
import '../../core/constants.dart';

/// Response from an LLM model query
class ModelResponse {
  final String content;
  final Map<String, dynamic>? reasoningDetails;

  ModelResponse({
    required this.content,
    this.reasoningDetails,
  });
}

/// Exception thrown when rate limited (429)
class RateLimitException implements Exception {
  final String model;
  RateLimitException(this.model);
  @override
  String toString() => 'Rate limited on model: $model';
}

/// Exception thrown when model not found (404)
class ModelNotFoundException implements Exception {
  final String model;
  ModelNotFoundException(this.model);
  @override
  String toString() => 'Model not found: $model';
}

/// Exception thrown for auth errors (401/403)
class AuthorizationException implements Exception {
  final String model;
  AuthorizationException(this.model);
  @override
  String toString() => 'Authorization error for model: $model';
}

/// OpenRouter API client for making LLM requests.
class OpenRouterClient {
  final Dio _dio;
  final String _apiKey;

  OpenRouterClient({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          baseUrl: OpenRouterConfig.baseUrl,
          connectTimeout: OpenRouterConfig.defaultTimeout,
          receiveTimeout: OpenRouterConfig.defaultTimeout,
          headers: {
            'Content-Type': 'application/json',
          },
        ));

  /// Query a single model
  Future<ModelResponse?> queryModel({
    required String model,
    required List<Map<String, String>> messages,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.post(
        OpenRouterConfig.chatCompletionsEndpoint,
        data: {
          'model': model,
          'messages': messages,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
          sendTimeout: timeout ?? OpenRouterConfig.defaultTimeout,
          receiveTimeout: timeout ?? OpenRouterConfig.defaultTimeout,
        ),
      );

      final data = response.data;
      final message = data['choices'][0]['message'];

      return ModelResponse(
        content: message['content'] ?? '',
        reasoningDetails: message['reasoning_details'],
      );
    } on DioException catch (e) {
      // Check for specific error codes
      if (e.response?.statusCode == 429) {
        print('Rate limited on model $model (429)');
        throw RateLimitException(model);
      } else if (e.response?.statusCode == 404) {
        print('Model not found: $model (404)');
        throw ModelNotFoundException(model);
      } else if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        print('Authorization error for $model');
        throw AuthorizationException(model);
      }
      print('Error querying model $model: ${e.message}');
      return null;
    } catch (e) {
      if (e is RateLimitException ||
          e is ModelNotFoundException ||
          e is AuthorizationException) {
        rethrow;
      }
      print('Unexpected error querying model $model: $e');
      return null;
    }
  }

  /// Query multiple models in parallel - continues even if some models fail
  Future<Map<String, ModelResponse?>> queryModelsParallel({
    required List<String> models,
    required List<Map<String, String>> messages,
  }) async {
    int rateLimitCount = 0;
    int modelNotFoundCount = 0;
    int authErrorCount = 0;

    final futures = models.map((model) async {
      try {
        final response = await queryModel(model: model, messages: messages);
        return MapEntry(model, response);
      } on RateLimitException {
        rateLimitCount++;
        print('Rate limited on $model - continuing with others');
        return MapEntry(model, null);
      } on ModelNotFoundException {
        modelNotFoundCount++;
        print('Model not found: $model - continuing with others');
        return MapEntry(model, null);
      } on AuthorizationException {
        authErrorCount++;
        print('Auth error on $model - continuing with others');
        return MapEntry(model, null);
      } catch (e) {
        print('Error on $model: $e - continuing with others');
        return MapEntry(model, null);
      }
    });

    final results = await Future.wait(futures);
    final resultsMap = Map.fromEntries(results);

    // Count successful responses
    final successCount = resultsMap.values.where((v) => v != null).length;

    // Only throw if ALL models failed with the same critical error
    if (successCount == 0) {
      if (rateLimitCount == models.length) {
        throw RateLimitException('all models');
      } else if (modelNotFoundCount == models.length) {
        throw ModelNotFoundException('all models');
      } else if (authErrorCount == models.length) {
        throw AuthorizationException('all models');
      }
    }

    return resultsMap;
  }

  /// Verify API key is valid by making a simple request
  Future<bool> verifyApiKey() async {
    try {
      final response = await queryModel(
        model: 'openai/gpt-4o-mini',
        messages: [
          {'role': 'user', 'content': 'Hi'}
        ],
        timeout: const Duration(seconds: 30),
      );
      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// Get available models from OpenRouter
  Future<List<Map<String, dynamic>>?> getAvailableModels() async {
    try {
      final response = await _dio.get(
        '/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching models: $e');
      return null;
    }
  }
}
