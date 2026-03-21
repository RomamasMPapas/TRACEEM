import 'package:flutter_test/flutter_test.dart';
import 'package:trace_em/domain/usecases/get_orders_usecase.dart';
import 'package:trace_em/domain/repositories/order_repository.dart';
import 'package:trace_em/domain/entities/order_entity.dart';
import 'package:trace_em/core/error/failures.dart';
import 'package:dartz/dartz.dart';

class MockOrderRepository implements OrderRepository {
  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    return Right([
      OrderEntity(
        id: '1',
        orderNumber: '10240',
        status: 'pending',
        progress: 0.5,
        date: DateTime.now(),
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GetOrdersUseCase useCase;
  late MockOrderRepository repository;

  setUp(() {
    repository = MockOrderRepository();
    useCase = GetOrdersUseCase(repository);
  });

  test('should return a list of orders from the repository', () async {
    // act
    final result = await useCase();

    // assert
    expect(result.isRight(), true);
    result.fold((failure) => fail('Should not return failure'), (orders) {
      expect(orders.isNotEmpty, true);
      expect(orders[0].orderNumber, '10240');
    });
  });
}
