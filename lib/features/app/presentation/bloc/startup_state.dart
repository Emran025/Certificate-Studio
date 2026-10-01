import '../../../institution/domain/entities/institution.dart';

enum StartupStatus { loading, loaded, failure }

class StartupState {
  const StartupState({
    this.status = StartupStatus.loading,
    this.institution,
    this.errorMessage,
  });

  final StartupStatus status;
  final Institution? institution;
  final Object? errorMessage;
}
