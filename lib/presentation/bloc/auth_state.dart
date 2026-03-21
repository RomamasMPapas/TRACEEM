import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Base class for all authentication states emitted by [AuthBloc].
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// The default state before any auth check has been performed, or after logout.
class AuthInitial extends AuthState {}

/// Emitted during async auth operations (login, sign up) to show a loading indicator.
class AuthLoading extends AuthState {}

/// Emitted when a user has successfully logged in or signed up.
/// Contains the authenticated [user]'s data.
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Emitted when an authentication operation fails.
/// Contains a [message] describing what went wrong.
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
