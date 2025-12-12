/// Core constants for the LLM Council app.
library;

/// OpenRouter API configuration
class OpenRouterConfig {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  static const String chatCompletionsEndpoint = '/chat/completions';
  static const Duration defaultTimeout = Duration(seconds: 120);
}

/// Default council models - premium selection for executives
class CouncilDefaults {
  static const List<String> councilModels = [
    'openai/gpt-4o',
    'anthropic/claude-sonnet-4',
    'google/gemini-2.5-flash-preview',
    'x-ai/grok-3-mini-beta',
  ];

  static const String chairmanModel = 'openai/gpt-4o';

  /// Executive preset configurations
  static const Map<String, List<String>> presets = {
    'Free Council': [
      'meta-llama/llama-3.3-70b-instruct:free',
      'google/gemma-3-27b-it:free',
      'mistralai/mistral-small-3.1-24b-instruct:free',
      'deepseek/deepseek-chat-v3-0324:free',
    ],
    'Premium Council': [
      'openai/gpt-4o',
      'anthropic/claude-sonnet-4',
      'google/gemini-2.5-flash-preview',
      'x-ai/grok-3-mini-beta',
    ],
    'Speed Council': [
      'openai/gpt-4o-mini',
      'anthropic/claude-3.5-haiku',
      'google/gemini-2.0-flash-001',
    ],
    'Deep Analysis': [
      'openai/o1',
      'anthropic/claude-sonnet-4',
      'google/gemini-2.5-pro-preview',
    ],
  };

  /// Free chairman model (used for title generation etc)
  static const String freeChairmanModel =
      'meta-llama/llama-3.3-70b-instruct:free';
}

/// Storage keys
class StorageKeys {
  static const String apiKey = 'openrouter_api_key';
  static const String biometricEnabled = 'biometric_enabled';
  static const String councilModels = 'council_models';
  static const String chairmanModel = 'chairman_model';
  static const String themeMode = 'theme_mode';
  static const String onboardingComplete = 'onboarding_complete';
}

/// Database configuration
class DatabaseConfig {
  static const String databaseName = 'llm_council.db';
  static const int databaseVersion = 1;
}
