import 'package:equatable/equatable.dart';

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
