import 'package:equatable/equatable.dart';

/// Represents the various states an order can be in during its lifecycle.
enum OrderStatus {
  toReceive,
  toDeliver,
  toPaid,
  inTransit,
  delivered,
  cancelled,
}

/// Represents a single order or delivery booking within the TRACE EM app.
/// Holds the order details, progress, and geographic region.
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

  /// Used by Equatable to compare OrderEntity instances for equality.
  /// Two instances with identical property values are considered equal.
  @override
  List<Object?> get props => [id, orderNumber, status, progress, date, region];
}
