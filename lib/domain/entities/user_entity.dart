import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String region; // Philippine region (e.g., "Region 7", "NCR")
  final String role; // 'user' or 'admin'

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.region = 'Region 7', // Default to Region 7 (Cebu)
    this.role = 'user', // Default role is user
  });

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    phoneNumber,
    address,
    region,
    role,
  ];
}
