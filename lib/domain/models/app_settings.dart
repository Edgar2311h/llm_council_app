import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

/// Application settings
class AppSettings extends Equatable {
  final List<String> councilModels;
  final String chairmanModel;
  final bool darkMode;
  final bool biometricEnabled;

  const AppSettings({
    required this.councilModels,
    required this.chairmanModel,
    this.darkMode = true,
    this.biometricEnabled = false,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      councilModels: CouncilDefaults.councilModels,
      chairmanModel: CouncilDefaults.chairmanModel,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      councilModels: (json['council_models'] as List).cast<String>(),
      chairmanModel: json['chairman_model'] as String,
      darkMode: json['dark_mode'] as bool? ?? true,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'council_models': councilModels,
        'chairman_model': chairmanModel,
        'dark_mode': darkMode,
        'biometric_enabled': biometricEnabled,
      };

  AppSettings copyWith({
    List<String>? councilModels,
    String? chairmanModel,
    bool? darkMode,
    bool? biometricEnabled,
  }) {
    return AppSettings(
      councilModels: councilModels ?? this.councilModels,
      chairmanModel: chairmanModel ?? this.chairmanModel,
      darkMode: darkMode ?? this.darkMode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  List<Object?> get props =>
      [councilModels, chairmanModel, darkMode, biometricEnabled];
}
