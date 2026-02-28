import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  const LoginSubmitted(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

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

class LogoutRequested extends AuthEvent {}
