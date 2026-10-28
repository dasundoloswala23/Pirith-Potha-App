part of 'app_update_cubit.dart';

sealed class AppUpdateState extends Equatable {
  const AppUpdateState();

  @override
  List<Object?> get props => [];
}

/// Before the first check finishes.
final class UpdateUnknown extends AppUpdateState {
  const UpdateUnknown();
}

final class UpdateNotRequired extends AppUpdateState {
  const UpdateNotRequired();
}

/// A newer patch exists. The user may carry on.
final class UpdateOptional extends AppUpdateState {
  const UpdateOptional(this.config, this.installedVersion);

  final VersionConfig config;
  final String installedVersion;

  @override
  List<Object?> get props => [config, installedVersion];
}

/// A newer minor or major exists. The app is blocked until it's installed.
final class UpdateMandatory extends AppUpdateState {
  const UpdateMandatory(this.config, this.installedVersion);

  final VersionConfig config;
  final String installedVersion;

  @override
  List<Object?> get props => [config, installedVersion];
}
