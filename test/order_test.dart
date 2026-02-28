import 'package:flutter_test/flutter_test.dart';
import 'package:trace_em/domain/usecases/get_orders_usecase.dart';
import 'package:trace_em/infrastructure/repositories/order_repository_impl.dart';

void main() {
  late GetOrdersUseCase useCase;
  late OrderRepositoryImpl repository;

  setUp(() {
    repository = OrderRepositoryImpl();
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
