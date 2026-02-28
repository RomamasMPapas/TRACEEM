import 'package:equatable/equatable.dart';

enum OrderStatus {
  toReceive,
  toDeliver,
  toPaid,
  inTransit,
  delivered,
  cancelled,
}

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String status;
  final double progress;
  final DateTime date;
  final String region; // Philippine region where order is placed

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.progress,
    required this.date,
    this.region = 'Region 7', // Default to Region 7 (Cebu)
  });

  @override
  List<Object?> get props => [id, orderNumber, status, progress, date, region];
}
