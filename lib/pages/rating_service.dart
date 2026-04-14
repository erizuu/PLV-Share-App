import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's rating as a lender
  Future<Map<String, dynamic>?> getLenderRating(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .doc('lender')
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting lender rating: $e');
      return null;
    }
  }

  // Get user's rating as a borrower
  Future<Map<String, dynamic>?> getBorrowerRating(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .doc('borrower')
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting borrower rating: $e');
      return null;
    }
  }

  /// Check if current user already rated another user
  /// Returns the rating data if found, null if not rated yet
  Future<Map<String, dynamic>?> getMyRatingFor(
    String ratedUserId,
    String ratingType,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('ratings')
          .doc(ratingType)
          .get();

      if (!doc.exists) return null;

      Map<String, dynamic> ratingData = doc.data() as Map<String, dynamic>;

      // Get ratings map (new structure)
      Map<String, dynamic> ratingsMap = ratingData['ratingsMap'] ?? {};

      // Check if current user's rating exists
      if (ratingsMap.containsKey(currentUserId)) {
        return ratingsMap[currentUserId] as Map<String, dynamic>;
      }

      return null; // Haven't rated yet
    } catch (e) {
      print('Error getting my rating: $e');
      return null;
    }
  }

  /// Submit a rating - returns true if successful, false if already rated or error
  Future<bool> submitRating({
    required String ratedUserId,
    required String ratingType, // 'lender' or 'borrower'
    required double rating,
    required String feedback,
    required String transactionId,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('\n═══════════════════════════════════════════════════════════');
      print('📝 SUBMITTING RATING');
      print('═══════════════════════════════════════════════════════════');
      print('Rater: $currentUserId');
      print('Rated User: $ratedUserId');
      print('Type: $ratingType');
      print('Rating: $rating');

      // Get current user data
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      String raterName = 'Unknown';
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        raterName = userData['fullName'] ?? 'Unknown';
      }

      // Reference to the rating document
      DocumentReference ratingDocRef = _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('ratings')
          .doc(ratingType);

      // Use atomic transaction to prevent race conditions
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot ratingSnapshot = await transaction.get(ratingDocRef);

        Map<String, dynamic> ratingData = ratingSnapshot.exists
            ? (ratingSnapshot.data() as Map<String, dynamic>)
            : {};

        // Get the ratings map
        Map<String, dynamic> ratingsMap = ratingData['ratingsMap'] ?? {};

        // CHECK: Has this user already rated?
        if (ratingsMap.containsKey(currentUserId)) {
          print('❌ USER ALREADY RATED - Cannot duplicate');
          throw Exception('already_rated');
        }

        // Create new review
        ratingsMap[currentUserId] = {
          'rating': rating,
          'feedback': feedback,
          'raterName': raterName,
          'timestamp': FieldValue.serverTimestamp(),
          'transactionId': transactionId.isNotEmpty ? transactionId : '',
        };

        // Calculate average rating
        double totalScore = 0;
        ratingsMap.values.forEach((review) {
          totalScore += (review['rating'] as num).toDouble();
        });
        double averageRating = ratingsMap.isNotEmpty
            ? totalScore / ratingsMap.length
            : 0;

        // Update the document
        transaction.set(ratingDocRef, {
          'averageRating': averageRating,
          'totalRatings': ratingsMap.length,
          'ratingsMap': ratingsMap,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      print('✅ RATING SUBMITTED SUCCESSFULLY');
      print('═══════════════════════════════════════════════════════════\n');
      return true;
    } on FirebaseException catch (e) {
      if (e.message?.contains('already_rated') ?? false) {
        print('❌ Already rated error');
        return false;
      }
      print('❌ Firestore Error: ${e.message}');
      return false;
    } catch (e) {
      if (e.toString().contains('already_rated')) {
        print('❌ Already rated - user cannot submit duplicate');
        return false;
      }
      print('❌ Error: $e');
      return false;
    }
  }

  // Get all reviews for a user as a list
  Future<List<Map<String, dynamic>>> getUserReviews(
    String userId,
    String ratingType, // 'lender' or 'borrower'
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .doc(ratingType)
          .get();

      if (!doc.exists) return [];

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Convert ratingsMap to list format
      Map<String, dynamic> ratingsMap = data['ratingsMap'] ?? {};

      List<Map<String, dynamic>> reviews = [];
      ratingsMap.forEach((raterId, reviewData) {
        if (reviewData is Map<String, dynamic>) {
          reviews.add({
            'ratedBy': raterId,
            ...reviewData, // Spread the review data (rating, feedback, raterName, etc)
          });
        }
      });

      return reviews;
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  // Stream to watch rating changes
  Stream<Map<String, dynamic>?> watchUserRating(
    String userId,
    String ratingType,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ratings')
        .doc(ratingType)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data() as Map<String, dynamic>;
          }
          return null;
        });
  }
}
