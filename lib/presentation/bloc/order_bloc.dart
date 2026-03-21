import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import 'order_event.dart';
import 'order_state.dart';

/// The BLoC responsible for managing the state of a user's order list.
/// Listens for [OrderEvent]s and emits [OrderState]s accordingly.
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetOrdersUseCase getOrdersUseCase;

  OrderBloc({required this.getOrdersUseCase}) : super(OrderInitial()) {
    // Handles fetching the order list. Emits [OrderLoading], then [OrdersLoaded] or [OrderError].
    on<FetchOrders>((event, emit) async {
      emit(OrderLoading());
      final result = await getOrdersUseCase();
      result.fold(
        (failure) => emit(OrderError(failure.message)),
        (orders) => emit(OrdersLoaded(orders)),
      );
    });
  }
}
