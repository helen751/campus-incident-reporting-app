import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  // changing the loading state
  void changeLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // removing old messages
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
  }

  // signing the user into CampusFire
  Future<bool> signIn({required String email, required String password}) async {
    clearMessages();
    changeLoading(true);

    try {
      final result = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(const Duration(seconds: 20));

      User? user = result.user;

      if (user == null) {
        errorMessage = 'We could not sign you in.';
        return false;
      }

      // getting the latest verification status
      await user.reload();
      user = _auth.currentUser;

      if (user == null) {
        errorMessage = 'We could not load your account.';
        return false;
      }

      // stopping unverified users from entering the dashboard
      if (!user.emailVerified) {
        await _auth.signOut();

        errorMessage = 'Your email is not verified. Open the verification link sent to your ALU email.';

        return false;
      }

      successMessage = 'Welcome back!';
      return true;
    } on TimeoutException {
      errorMessage =
          'Firebase took too long to respond. Check your internet connection.';

      return false;
    } on FirebaseAuthException catch (error) {
      errorMessage = firebaseMessage(error.code);
      return false;
    } catch (error) {
      debugPrint('Login error: $error');

      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      changeLoading(false);
    }
  }

  // creating a new CampusFire account
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    clearMessages();
    changeLoading(true);

    try {
      final result = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(const Duration(seconds: 20));

      final user = result.user;

      if (user == null) {
        errorMessage = 'We could not create your account.';
        return false;
      }

      // updating the user's Firebase name
      await user
          .updateDisplayName(fullName.trim())
          .timeout(const Duration(seconds: 10));

      // storing the user's information in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
            'fullName': fullName.trim(),
            'email': email.trim(),
            'role': role,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 20));

      // sending the verification email
      await user.sendEmailVerification().timeout(const Duration(seconds: 15));

      // signing out until the email is verified
      await _auth.signOut().timeout(const Duration(seconds: 10));

      successMessage = 'Account created. Check your ALU email and verify your account before signing in.';

      return true;
    } on TimeoutException {
      debugPrint('Firebase request timed out');

      // preventing an incomplete account from remaining logged in
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      errorMessage = 'Firebase took too long to respond. Check your connection and try again.';

      return false;
    } on FirebaseAuthException catch (error) {
      debugPrint('Firebase authentication error: ${error.code}');

      errorMessage = firebaseMessage(error.code);
      return false;
    } on FirebaseException catch (error) {
      debugPrint('Firestore error: ${error.code} - ${error.message}');

      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      errorMessage =
          error.message ?? 'We could not save your account information.';

      return false;
    } catch (error) {
      debugPrint('Signup error: $error');

      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      // stopping the loading sign after the operation
      changeLoading(false);
    }
  }

  // signing the user out
  Future<void> signOut() async {
    changeLoading(true);

    try {
      await _auth.signOut();
    } finally {
      changeLoading(false);
    }
  }

  // returning understandable Firebase messages
  String firebaseMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';

      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
