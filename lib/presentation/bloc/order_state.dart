import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

/// Base class for all order-related states emitted by [OrderBloc].
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// The default state before any orders have been fetched.
class OrderInitial extends OrderState {}

/// Emitted while the app is fetching orders from the repository.
class OrderLoading extends OrderState {}

/// Emitted when orders have been successfully fetched.
/// Contains the full list of [orders] to display in the UI.
class OrdersLoaded extends OrderState {
  final List<OrderEntity> orders;
  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

/// Emitted when the order fetching fails.
/// Contains a [message] describing the error.
class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
