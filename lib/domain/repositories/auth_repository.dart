import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Abstract contract defining all authentication-related operations.
/// Concrete implementations are provided in the infrastructure layer.
abstract class AuthRepository {
  /// Authenticates a user with their [username] and [password].
  Future<Either<Failure, UserEntity>> login(String username, String password);
  /// Registers a new user account with the given personal details.
  Future<Either<Failure, UserEntity>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  });
  /// Updates an existing user's profile with the given details.
  Future<Either<Failure, UserEntity>> updateProfile({
    required String id,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    String? photoUrl,
  });
  /// Fetches the currently authenticated user, or null if no session is active.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Starts the phone number verification process.
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Failure failure) onVerificationFailed,
  });

  /// Completes the sign-in process using the [verificationId] and [smsCode].
  Future<Either<Failure, UserEntity>> signInWithOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Signs the current user out of the application.
  Future<Either<Failure, void>> logout();
}
