import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a borrowing request
  Future<Map<String, dynamic>> createRequest({
    required String itemId,
    required String itemName,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Get borrower data
      final borrowerDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final borrowerData = borrowerDoc.data();

      final requestData = {
        'itemId': itemId,
        'itemName': itemName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'borrowerId': user.uid,
        'borrowerName': borrowerData?['fullName'] ?? 'Unknown',
        'borrowerSchoolId': borrowerData?['schoolId'] ?? '',
        'status': 'pending', // pending, accepted, declined
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('requests').add(requestData);

      return {
        'success': true,
        'message': 'Request sent successfully',
        'requestId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating request: ${e.toString()}',
      };
    }
  }

  // Get requests for item owner (incoming requests)
  Stream<QuerySnapshot> getIncomingRequests(String ownerId) {
    return _firestore
        .collection('requests')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get requests made by borrower (outgoing requests)
  Stream<QuerySnapshot> getOutgoingRequests(String borrowerId) {
    return _firestore
        .collection('requests')
        .where('borrowerId', isEqualTo: borrowerId)
        .snapshots();
  }

  // Accept a request with optional transaction end date
  Future<Map<String, dynamic>> acceptRequest(
    String requestId,
    String itemId, {
    DateTime? transactionEndDate,
  }) async {
    try {
      // Update request status
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'accepted',
        'transactionEndDate': transactionEndDate != null
            ? Timestamp.fromDate(transactionEndDate)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update item status to borrowed
      await _firestore.collection('items').doc(itemId).update({
        'status': 'borrowed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Request accepted'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error accepting request: ${e.toString()}',
      };
    }
  }

  // Decline a request
  Future<Map<String, dynamic>> declineRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Request declined'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error declining request: ${e.toString()}',
      };
    }
  }

  // Cancel a request (borrower cancels their own request)
  Future<Map<String, dynamic>> cancelRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Request cancelled'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error cancelling request: ${e.toString()}',
      };
    }
  }

  // Get request details
  Future<Map<String, dynamic>?> getRequest(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {...data, 'id': doc.id};
    } catch (e) {
      print('Error getting request: $e');
      return null;
    }
  }

  // End transaction and update related chat room
  Future<Map<String, dynamic>> endTransaction(String requestId) async {
    try {
      // Update request status to completed
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Transaction ended'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error ending transaction: ${e.toString()}',
      };
    }
  }
}
