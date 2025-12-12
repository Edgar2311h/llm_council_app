import 'package:equatable/equatable.dart';

/// Settings events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class SaveApiKey extends SettingsEvent {
  final String apiKey;

  const SaveApiKey(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}

class VerifyApiKey extends SettingsEvent {
  final String apiKey;

  const VerifyApiKey(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}

class UpdateCouncilModels extends SettingsEvent {
  final List<String> models;

  const UpdateCouncilModels(this.models);

  @override
  List<Object?> get props => [models];
}

class UpdateChairmanModel extends SettingsEvent {
  final String model;

  const UpdateChairmanModel(this.model);

  @override
  List<Object?> get props => [model];
}

class CompleteOnboarding extends SettingsEvent {}

class ClearAllData extends SettingsEvent {}
