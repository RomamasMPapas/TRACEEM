import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for handling the user login flow.
/// Delegates the actual authentication logic to the [AuthRepository].
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Executes the login action with the provided [username] and [password].
  /// Returns either a [Failure] on error, or a [UserEntity] on success.
  Future<Either<Failure, UserEntity>> call(
    String username,
    String password,
  ) async {
    return await repository.login(username, password);
  }
}
