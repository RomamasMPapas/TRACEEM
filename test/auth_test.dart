import 'package:flutter_test/flutter_test.dart';
import 'package:trace_em/domain/usecases/login_usecase.dart';
import 'package:trace_em/domain/repositories/auth_repository.dart';
import 'package:trace_em/domain/entities/user_entity.dart';
import 'package:trace_em/core/error/failures.dart';
import 'package:dartz/dartz.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> login(String username, String password) async {
    if (username == 'admin' && password == 'password') {
      return const Right(UserEntity(
        id: '1',
        username: 'admin',
        email: 'admin@test.com',
        phoneNumber: '12345',
        address: 'test',
      ));
    }
    return Left(AuthFailure('Invalid credentials'));
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String id,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    String? photoUrl,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> logout() async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Failure failure) onVerificationFailed,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  test('should return UserEntity when credentials are correct', () async {
    // arrange
    const tUsername = 'admin';
    const tPassword = 'password';

    // act
    final result = await useCase(tUsername, tPassword);

    // assert
    expect(result.isRight(), true);
  });

  test('should return Failure when credentials are wrong', () async {
    // arrange
    const tUsername = 'admin';
    const tPassword = 'wrong';

    // act
    final result = await useCase(tUsername, tPassword);

    // assert
    expect(result.isLeft(), true);
  });
}
