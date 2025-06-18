import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register new user and send verification email
  Future<String?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.sendEmailVerification(); // Send verification email
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // Login existing user and check email verification
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!result.user!.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email before logging in.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Resend email verification to currently signed-in user
  Future<void> resendVerificationEmail(String email) async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Optional: Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Optional: Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
