import 'package:equatable/equatable.dart';

/// Represents a user entity within the TRACE EM domain.
/// Stores application user details including role, contact info, and their configured Philippine region.
class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String region; // Philippine region (e.g., "Region 7", "NCR")
  final String role; // 'user' or 'admin'
  final String? photoUrl; // URL to the user's profile picture

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.region = 'Region 7', // Default to Region 7 (Cebu)
    this.role = 'user', // Default role is user
    this.photoUrl,
  });

  /// Exposes properties for the Equatable package to compare `UserEntity` instances.
  /// Used primarily to check if a user's details have changed.
  @override
  List<Object?> get props => [
    id,
    username,
    email,
    phoneNumber,
    address,
    region,
    role,
    photoUrl,
  ];
}
