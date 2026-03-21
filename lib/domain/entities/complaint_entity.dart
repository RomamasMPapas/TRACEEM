import 'package:equatable/equatable.dart';

/// Represents a user complaint or report within the TRACE EM domain.
/// Holds the details such as who made it, the status, and any admin responses.
class ComplaintEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String description;
  final String status; // 'pending', 'resolved'
  final DateTime createdAt;
  final String? response;

  const ComplaintEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.response,
  });

  /// Used by Equatable to compare instances for equality.
  /// Any two instances with the exact same properties below will be considered equal.
  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    description,
    status,
    createdAt,
    response,
  ];
}
