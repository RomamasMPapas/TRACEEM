import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Either<Failure, UserEntity>> login(
    String username,
    String password,
  ) async {
    try {
      // Assuming 'username' is email for Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: username,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return Left(AuthFailure('Login failed'));
      }

      // Fetch user details from Firestore
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return Right(
          UserEntity(
            id: user.uid,
            username: data['username'] ?? '',
            email: user.email ?? '',
            phoneNumber: data['phoneNumber'] ?? '',
            address: data['address'] ?? '',
            region: data['region'] ?? 'Region 7',
            role: data['role'] ?? 'user',
          ),
        );
      } else {
        // Debugging aid: Print the UID that was looked for
        print(
          'DEBUG: Auth Success. Looking for Firestore doc with ID: ${user.uid}',
        );
        return Left(
          AuthFailure(
            'User data not found for UID: ${user.uid}. \nEnsure Firestore "users" collection has a document with this ID.',
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Login failed'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return Left(AuthFailure('Sign up failed'));
      }

      // Save user details to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'username': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'role': 'user', // Default role for new signups
        'createdAt': FieldValue.serverTimestamp(),
      });

      return Right(
        UserEntity(
          id: user.uid,
          username: fullName,
          email: email,
          phoneNumber: phoneNumber,
          address: address,
          role: 'user',
        ),
      );
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Sign up failed'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String id,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('No user logged in'));

      // Update email if changed
      if (email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      // Update password if provided
      if (password.isNotEmpty) {
        await user.updatePassword(password);
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'username': fullName,
        'phoneNumber': phoneNumber,
        'address': address,
      });

      // Fetch updated data to return correct entity
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final data = docSnapshot.data()!;

      return Right(
        UserEntity(
          id: user.uid,
          username: data['username'] ?? fullName,
          email: user.email ?? email,
          phoneNumber: data['phoneNumber'] ?? phoneNumber,
          address: data['address'] ?? address,
          region: data['region'] ?? 'Region 7',
          role: data['role'] ?? 'user',
        ),
      );
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Update failed'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return const Right(null);

      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return Right(
          UserEntity(
            id: user.uid,
            username: data['username'] ?? '',
            email: user.email ?? '',
            phoneNumber: data['phoneNumber'] ?? '',
            address: data['address'] ?? '',
            region: data['region'] ?? 'Region 7',
            role: data['role'] ?? 'user',
          ),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _firebaseAuth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
