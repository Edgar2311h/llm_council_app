import 'package:equatable/equatable.dart';
import '../../../domain/models/app_settings.dart';

/// Settings state
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  final bool hasApiKey;
  final bool isOnboardingComplete;

  const SettingsLoaded({
    required this.settings,
    required this.hasApiKey,
    required this.isOnboardingComplete,
  });

  @override
  List<Object?> get props => [settings, hasApiKey, isOnboardingComplete];

  SettingsLoaded copyWith({
    AppSettings? settings,
    bool? hasApiKey,
    bool? isOnboardingComplete,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ApiKeyVerifying extends SettingsState {}

class ApiKeyValid extends SettingsState {}

class ApiKeyInvalid extends SettingsState {
  final String message;

  const ApiKeyInvalid(this.message);

  @override
  List<Object?> get props => [message];
}
