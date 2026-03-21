import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for signing the current user out of the application.
/// Delegates the actual logout logic to the [AuthRepository].
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// Executes the logout action for the currently authenticated user.
  /// Returns either a [Failure] on error, or void on success.
  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
