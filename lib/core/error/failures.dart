/// Base class for all recoverable, expected failures in the app.
/// Unlike raw exceptions, these carry a human-readable [message] that's
/// already safe to show directly in the UI (a SnackBar, dialog, etc.).
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class RecordingFailure extends Failure {
  const RecordingFailure(super.message);
}

class ProcessingFailure extends Failure {
  const ProcessingFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ImportFailure extends Failure {
  const ImportFailure(super.message);
}
