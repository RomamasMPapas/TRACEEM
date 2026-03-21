/// Base class representing a failure state in the application.
/// All specific error types should inherit from this to provide a consistent failure message.
abstract class Failure {
  final String message;
  Failure(this.message);
}

/// Represents an error that originated from the backend server or API.
class ServerFailure extends Failure {
  ServerFailure(super.message);
}

/// Represents an error related to reading from or writing to local device storage.
class CacheFailure extends Failure {
  CacheFailure(super.message);
}

/// Represents an error that occurs during user authentication processes (e.g. login/signup failure).
class AuthFailure extends Failure {
  AuthFailure(super.message);
}
