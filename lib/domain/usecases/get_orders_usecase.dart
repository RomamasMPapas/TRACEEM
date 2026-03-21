import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

/// Use case responsible for fetching all orders for the current user.
/// Delegates the data retrieval to [OrderRepository].
class GetOrdersUseCase {
  final OrderRepository repository;

  GetOrdersUseCase(this.repository);

  /// Fetches the full list of orders.
  /// Returns either a [Failure] on error, or a [List<OrderEntity>] on success.
  Future<Either<Failure, List<OrderEntity>>> call() async {
    return await repository.getOrders();
  }
}
