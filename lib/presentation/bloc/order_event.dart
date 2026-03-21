import 'package:equatable/equatable.dart';

/// Base class for all order-related events dispatched to [OrderBloc].
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the app needs to load the current user's list of orders.
class FetchOrders extends OrderEvent {}
