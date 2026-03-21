import 'package:equatable/equatable.dart';

/// Base class for all authentication-related events dispatched to [AuthBloc].
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app startup to check if a user session already exists.
class AuthCheckRequested extends AuthEvent {}

/// Fired when the user submits the login form with their [username] and [password].
class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  const LoginSubmitted(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

/// Fired when the user submits the sign-up form with their new account details.
class SignUpSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String address;

  const SignUpSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.address,
  });

  @override
  List<Object?> get props => [fullName, email, password, phoneNumber, address];
}

/// Fired when the user saves changes to their profile.
class UpdateProfileSubmitted extends AuthEvent {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String address;

  const UpdateProfileSubmitted({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.address,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    password,
    phoneNumber,
    address,
  ];
}

/// Fired when the user taps the logout button.
class LogoutRequested extends AuthEvent {}
