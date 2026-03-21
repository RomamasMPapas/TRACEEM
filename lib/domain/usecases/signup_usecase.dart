import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for handling the user registration (sign up) flow.
/// Delegates the actual sign-up logic to the [AuthRepository].
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  /// Executes the sign-up action with the provided user details.
  /// Returns either a [Failure] on error, or a [UserEntity] on success.
  Future<Either<Failure, UserEntity>> call({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  }) async {
    return await repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      address: address,
    );
  }
}
