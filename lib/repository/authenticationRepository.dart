import 'dart:async';

import 'package:TimeliNUS/models/userModel.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';

// Thrown if during the sign up process if a failure occurs.

class AuthenticationFailture implements Exception {
  String cause;
  AuthenticationFailture(this.cause);

  @override
  String toString() {
    return "Authentication Failure: " + cause;
  }
}

class SignUpFailure implements AuthenticationFailture {
  String cause;
  SignUpFailure(this.cause);
}

/// Thrown during the login process if a failure occurs.
class LogInWithEmailAndPasswordFailure implements Exception {}

/// Thrown during the sign in with google process if a failure occurs.
class LogInWithGoogleFailure implements Exception {}

/// Thrown during the logout process if a failure occurs.
class LogOutFailure implements Exception {}

class AuthenticationRepository {
  /// {@macro authentication_repository}
  AuthenticationRepository({
    FirebaseAuth.FirebaseAuth firebaseAuth,
    GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  final FirebaseAuth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  User _currentUser;

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits [User.empty] if the user is not authenticated.
  Stream<User> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      final user = firebaseUser == null ? User.empty : firebaseUser.toUser;
      _currentUser = user;
      return user;
    });
  }

  /// Returns the current cached user.
  /// Defaults to [User.empty] if there is no cached user.
  User get currentUser {
    return _currentUser;
  }

  /// Creates a new user with the provided [email] and [password].
  ///
  /// Throws a [SignUpFailure] if an exception occurs.
  Future<void> signUp(
      {@required String email, @required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuth.FirebaseAuthException catch (err) {
      throw AuthenticationFailture(err.code);
    }
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [logInWithGoogle] if an exception occurs.
  Future<void> logInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      final googleAuth = await googleUser.authentication;
      final credential = FirebaseAuth.GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuth.FirebaseAuthException catch (err) {
      throw AuthenticationFailture(err.code);
    }
  }

  /// Signs in with the provided [email] and [password].
  ///
  /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
  Future<void> logInWithEmailAndPassword({
    @required String email,
    @required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuth.FirebaseAuthException catch (err) {
      throw AuthenticationFailture(err.code);
    }
  }

  /// Signs out the current user which will emit
  /// [User.empty] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  Future<void> logOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } on Exception {
      throw LogOutFailure();
    }
  }
}

extension on FirebaseAuth.User {
  User get toUser {
    return User(id: uid, email: email, name: displayName);
  }
}