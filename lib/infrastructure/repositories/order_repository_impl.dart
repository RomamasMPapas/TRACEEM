import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

/// Concrete Firebase implementation of [OrderRepository].
/// Fetches order data from Firestore for the currently authenticated user.
class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Queries Firestore for all orders belonging to the current user.
  /// Returns a [List<OrderEntity>] on success, or a [ServerFailure] if an error occurs.
  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      // Query orders for the current user
      // Assuming 'userId' field exists in order documents
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return OrderEntity(
          id: doc.id,
          orderNumber: data['orderNumber'] ?? 'UNKNOWN',
          status: data['status'] ?? 'pending',
          progress: (data['progress'] ?? 0.0).toDouble(),
          date: (data['date'] is Timestamp)
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
          region: data['region'] ?? 'Region 7', // Default to Region 7
        );
      }).toList();

      return Right(orders);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
