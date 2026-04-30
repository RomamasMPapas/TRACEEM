import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete Firebase implementation of [AuthRepository].
/// Handles all authentication and user profile operations via Firebase Auth and Firestore.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Authenticates the user with email and password via Firebase Auth.
  /// On success, fetches the user's profile from Firestore and returns a [UserEntity].
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

  /// Creates a new user account in Firebase Auth, then saves the profile data to Firestore.
  /// Returns the newly created [UserEntity] on success.
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

  /// Updates the current user's email, password, and Firestore profile data.
  /// Returns the refreshed [UserEntity] after the update is applied.
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

  /// Checks if a user session is active and fetches their full profile from Firestore.
  /// Returns null (not an error) if no user is currently signed in.
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

  /// Starts the Firebase Phone Auth verification process.
  @override
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Failure failure) onVerificationFailed,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // This can happen automatically on some Android devices
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(AuthFailure(e.message ?? 'Verification failed'));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout if needed
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  /// Completes the sign-in using the verification ID and the SMS code provided by the user.
  @override
  Future<Either<Failure, UserEntity>> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return Left(AuthFailure('Sign in failed'));

      // Fetch or create user in Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists) {
        // For new users signed in via Phone, we create a default profile
        await _firestore.collection('users').doc(user.uid).set({
          'phoneNumber': user.phoneNumber ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final data = (await _firestore.collection('users').doc(user.uid).get()).data()!;

      return Right(
        UserEntity(
          id: user.uid,
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: user.phoneNumber ?? '',
          address: data['address'] ?? '',
          role: data['role'] ?? 'user',
        ),
      );
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'OTP Verification failed'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  /// Signs the current user out of their Firebase session.
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
