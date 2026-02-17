import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'fullName': fullName,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'verificationStatus': 'pending', // pending, approved, rejected
        'hasSeenTutorial': false,
      });

      return {'success': true, 'uid': userCredential.user!.uid};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Update user profile with academic info
  Future<bool> updateUserProfile({
    required String uid,
    required String schoolId,
    required String course,
    required String section,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'schoolId': schoolId,
        'course': course,
        'section': section,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update verification documents
  Future<bool> updateVerificationInfo({
    required String uid,
    required String verificationType,
    String? frontIdPath,
    String? backIdPath,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'verificationType': verificationType,
        'frontIdPath': frontIdPath,
        'backIdPath': backIdPath,
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating verification: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      return {
        'success': true,
        'uid': userCredential.user!.uid,
        'userData': userDoc.data(),
      };
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = e.message ?? 'Login failed';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Failed to send reset email',
      };
    }
  }

  // Mark tutorial as seen
  Future<bool> markTutorialAsSeen() async {
    try {
      if (currentUser == null) return false;
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'hasSeenTutorial': true,
      });
      return true;
    } catch (e) {
      print('Error marking tutorial as seen: $e');
      return false;
    }
  }

  // Check if user has seen tutorial
  Future<bool> hasSeenTutorial() async {
    try {
      if (currentUser == null) return true; // Default to true if no user
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return true;

      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      return data?['hasSeenTutorial'] ?? false;
    } catch (e) {
      print('Error checking tutorial status: $e');
      return true; // Default to true on error to avoid blocking
    }
  }
}
