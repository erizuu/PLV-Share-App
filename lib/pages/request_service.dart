import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the status of a borrow request
  Future<String?> getRequestStatus(String transactionId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('borrow_requests')
          .doc(transactionId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['status'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting request status: $e');
      return null;
    }
  }

  /// Accept a borrow request
  Future<bool> acceptRequest(String transactionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('borrow_requests').doc(transactionId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedBy': currentUserId,
      });

      print('✅ Request accepted: $transactionId');
      return true;
    } catch (e) {
      print('❌ Error accepting request: $e');
      return false;
    }
  }

  /// Decline a borrow request
  Future<bool> declineRequest(String transactionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('borrow_requests').doc(transactionId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
        'declinedBy': currentUserId,
      });

      print('✅ Request declined: $transactionId');
      return true;
    } catch (e) {
      print('❌ Error declining request: $e');
      return false;
    }
  }

  /// Stream to watch request status changes
  Stream<String?> watchRequestStatus(String transactionId) {
    return _firestore
        .collection('borrow_requests')
        .doc(transactionId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            return data['status'] as String?;
          }
          return null;
        });
  }
}
