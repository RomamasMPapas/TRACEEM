import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetOrdersUseCase getOrdersUseCase;

  OrderBloc({required this.getOrdersUseCase}) : super(OrderInitial()) {
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
