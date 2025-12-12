import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../../../data/api/openrouter_client.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/storage/secure_storage_service.dart';
import '../../../domain/models/app_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SecureStorageService _secureStorage;
  final DatabaseHelper _database;

  SettingsBloc({
    SecureStorageService? secureStorage,
    DatabaseHelper? database,
  })  : _secureStorage = secureStorage ?? SecureStorageService.instance,
        _database = database ?? DatabaseHelper.instance,
        super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveApiKey>(_onSaveApiKey);
    on<VerifyApiKey>(_onVerifyApiKey);
    on<UpdateCouncilModels>(_onUpdateCouncilModels);
    on<UpdateChairmanModel>(_onUpdateChairmanModel);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<ClearAllData>(_onClearAllData);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    try {
      final hasApiKey = await _secureStorage.hasApiKey();
      final isOnboardingComplete = await _secureStorage.isOnboardingComplete();

      // Load settings from database
      final councilModelsJson =
          await _database.getSetting(StorageKeys.councilModels);
      final chairmanModel =
          await _database.getSetting(StorageKeys.chairmanModel);

      List<String> councilModels = CouncilDefaults.councilModels;
      if (councilModelsJson != null) {
        councilModels = (jsonDecode(councilModelsJson) as List).cast<String>();
      }

      final settings = AppSettings(
        councilModels: councilModels,
        chairmanModel: chairmanModel ?? CouncilDefaults.chairmanModel,
      );

      emit(SettingsLoaded(
        settings: settings,
        hasApiKey: hasApiKey,
        isOnboardingComplete: isOnboardingComplete,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onSaveApiKey(
    SaveApiKey event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _secureStorage.saveApiKey(event.apiKey);

      if (state is SettingsLoaded) {
        emit((state as SettingsLoaded).copyWith(hasApiKey: true));
      } else {
        add(LoadSettings());
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onVerifyApiKey(
    VerifyApiKey event,
    Emitter<SettingsState> emit,
  ) async {
    emit(ApiKeyVerifying());

    try {
      final client = OpenRouterClient(apiKey: event.apiKey);
      final isValid = await client.verifyApiKey();

      if (isValid) {
        await _secureStorage.saveApiKey(event.apiKey);
        emit(ApiKeyValid());
        // Reload settings to update state
        add(LoadSettings());
      } else {
        emit(const ApiKeyInvalid(
            'Invalid API key. Please check and try again.'));
      }
    } catch (e) {
      emit(ApiKeyInvalid(e.toString()));
    }
  }

  Future<void> _onUpdateCouncilModels(
    UpdateCouncilModels event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _database.saveSetting(
        StorageKeys.councilModels,
        jsonEncode(event.models),
      );

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        emit(currentState.copyWith(
          settings: currentState.settings.copyWith(councilModels: event.models),
        ));
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateChairmanModel(
    UpdateChairmanModel event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _database.saveSetting(StorageKeys.chairmanModel, event.model);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        emit(currentState.copyWith(
          settings: currentState.settings.copyWith(chairmanModel: event.model),
        ));
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _secureStorage.setOnboardingComplete(true);

      if (state is SettingsLoaded) {
        emit((state as SettingsLoaded).copyWith(isOnboardingComplete: true));
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onClearAllData(
    ClearAllData event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _secureStorage.clearAll();
      await _database.clearAllData();
      emit(SettingsLoaded(
        settings: AppSettings.defaults(),
        hasApiKey: false,
        isOnboardingComplete: false,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
