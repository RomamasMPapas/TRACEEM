import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case responsible for updating the currently logged-in user's profile details.
/// Delegates the update logic to the [AuthRepository].
class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  /// Executes the profile update with the provided user fields.
  /// Returns either a [Failure] on error, or the updated [UserEntity] on success.
  Future<Either<Failure, UserEntity>> call({
    required String id,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    String? photoUrl,
  }) async {
    return await repository.updateProfile(
      id: id,
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      address: address,
      photoUrl: photoUrl,
    );
  }
}
