import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/order_entity.dart';

/// Abstract contract defining all order-related data operations.
/// Concrete implementations are provided in the infrastructure layer.
abstract class OrderRepository {
  /// Retrieves all orders available for the current user.
  Future<Either<Failure, List<OrderEntity>>> getOrders();
}
