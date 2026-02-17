import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new item
  Future<Map<String, dynamic>> addItem({
    required String itemName,
    required String category,
    required String description,
    required String timeline,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final itemData = {
        'itemName': itemName,
        'category': category,
        'description': description,
        'timeline': timeline,
        'imageUrl': imageUrl ?? '',
        'ownerId': user.uid,
        'ownerName': userData?['fullName'] ?? 'Unknown',
        'ownerSchoolId': userData?['schoolId'] ?? '',
        'status': 'available', // available, borrowed, unavailable
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'borrowCount': 0,
      };

      final docRef = await _firestore.collection('items').add(itemData);

      return {
        'success': true,
        'message': 'Item posted successfully',
        'itemId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error posting item: ${e.toString()}',
      };
    }
  }

  // Get user's items
  Stream<QuerySnapshot> getUserItems(String userId) {
    return _firestore
        .collection('items')
        .where('ownerId', isEqualTo: userId)
        .snapshots();
  }

  // Get all available items
  Stream<QuerySnapshot> getAllItems() {
    return _firestore
        .collection('items')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  // Get items by category
  Stream<QuerySnapshot> getItemsByCategory(String category) {
    return _firestore
        .collection('items')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'available')
        .where('category', isEqualTo: category)
        .snapshots();
  }

  // Update item status
  Future<Map<String, dynamic>> updateItemStatus({
    required String itemId,
    required String status,
  }) async {
    try {
      await _firestore.collection('items').doc(itemId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Item status updated'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating status: ${e.toString()}',
      };
    }
  }

  // Delete item
  Future<Map<String, dynamic>> deleteItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Item deleted successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting item: ${e.toString()}',
      };
    }
  }

  // Get item stats for user
  Future<Map<String, int>> getUserItemStats(String userId) async {
    try {
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int activeLoans = 0;
      int totalShares = 0;

      for (var doc in itemsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'borrowed') {
          activeLoans++;
        }
        totalShares += (data['borrowCount'] as num?)?.toInt() ?? 0;
      }

      return {
        'activeLoans': activeLoans,
        'totalShares': totalShares,
        'totalItems': itemsSnapshot.docs.length,
      };
    } catch (e) {
      return {'activeLoans': 0, 'totalShares': 0, 'totalItems': 0};
    }
  }
}
