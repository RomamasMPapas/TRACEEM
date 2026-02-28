import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/check_auth_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final CheckAuthUseCase checkAuthUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.signUpUseCase,
    required this.updateProfileUseCase,
    required this.checkAuthUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) async {
      final result = await checkAuthUseCase();
      result.fold(
        (failure) => emit(AuthInitial()), // Non-authenticated or error
        (user) {
          if (user != null) {
            emit(AuthAuthenticated(user));
          } else {
            emit(AuthInitial());
          }
        },
      );
    });

    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await loginUseCase(event.username, event.password);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<SignUpSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await signUpUseCase(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        phoneNumber: event.phoneNumber,
        address: event.address,
      );
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<UpdateProfileSubmitted>((event, emit) async {
      final result = await updateProfileUseCase(
        id: event.id,
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        phoneNumber: event.phoneNumber,
        address: event.address,
      );
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<LogoutRequested>((event, emit) async {
      final result = await logoutUseCase();
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(AuthInitial()),
      );
    });
  }
}
