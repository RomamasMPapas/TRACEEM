import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String username, String password);
  Future<Either<Failure, UserEntity>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  });
  Future<Either<Failure, UserEntity>> updateProfile({
    required String id,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  });
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> logout();
}
