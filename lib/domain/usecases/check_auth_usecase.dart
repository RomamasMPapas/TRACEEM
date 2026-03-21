import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case that checks whether a user is currently logged in.
/// Used typically on app startup to determine if the user should see the home screen or login screen.
class CheckAuthUseCase {
  final AuthRepository repository;

  CheckAuthUseCase(this.repository);

  /// Executes the auth check. Returns a [UserEntity] if a user is logged in, or null if not.
  /// Returns a [Failure] if the check itself could not be completed.
  Future<Either<Failure, UserEntity?>> call() async {
    return await repository.getCurrentUser();
  }
}
