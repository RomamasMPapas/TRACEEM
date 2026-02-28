import 'package:flutter_test/flutter_test.dart';
import 'package:trace_em/domain/usecases/login_usecase.dart';
import 'package:trace_em/infrastructure/repositories/auth_repository_impl.dart';

void main() {
  late LoginUseCase useCase;
  late AuthRepositoryImpl repository;

  setUp(() {
    repository = AuthRepositoryImpl();
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
