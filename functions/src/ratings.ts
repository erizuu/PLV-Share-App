import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function: submitRating
 * Handles rating submission with proper duplicate detection
 */
export const submitRating = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const {
    ratedUserId,
    ratingType, // 'lender' or 'borrower'
    rating,
    feedback,
    transactionId,
  } = data;

  const currentUserId = context.auth.uid;

  // Validate inputs
  if (!ratedUserId || !ratingType || !rating || !feedback) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  if (rating < 1 || rating > 5) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Rating must be between 1 and 5'
    );
  }

  if (currentUserId === ratedUserId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Cannot rate yourself'
    );
  }

  try {
    // Get the rated user's rating document
    const ratingDocRef = db
      .collection('users')
      .doc(ratedUserId)
      .collection('ratings')
      .doc(ratingType);

    const ratingSnapshot = await ratingDocRef.get();
    let ratingData = ratingSnapshot.exists ? ratingSnapshot.data() : null;

    // Check if current user already rated
    if (ratingData && ratingData.reviews) {
      const alreadyRated = ratingData.reviews.some(
        (review: any) => review.ratedBy === currentUserId
      );

      if (alreadyRated) {
        throw new functions.https.HttpsError(
          'already-exists',
          'You have already rated this user'
        );
      }
    }

    // Get current user data for the review
    const currentUserSnapshot = await db.collection('users').doc(currentUserId).get();
    const currentUserData = currentUserSnapshot.data();
    const currentUserName = currentUserData?.fullName || 'User';

    // Create new review
    const newReview = {
      ratedBy: currentUserId,
      ratedByName: currentUserName,
      rating: rating,
      feedback: feedback,
      ratingType: ratingType,
      transactionId: transactionId || '',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Update rating document
    let reviews = ratingData?.reviews || [];
    reviews.push(newReview);

    // Calculate new average
    const totalScore = reviews.reduce((sum: number, r: any) => sum + (r.rating || 0), 0);
    const averageRating = reviews.length > 0 ? totalScore / reviews.length : 0;

    // Write to Firestore
    await ratingDocRef.set({
      averageRating: averageRating,
      totalRatings: reviews.length,
      reviews: reviews,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: 'Rating submitted successfully',
      averageRating: averageRating,
    };
  } catch (error) {
    console.error('Error submitting rating:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to submit rating'
    );
  }
});

/**
 * Cloud Function: getMyRating
 * Retrieves the current user's rating for another user
 */
export const getMyRating = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { ratedUserId, ratingType } = data;
  const currentUserId = context.auth.uid;

  if (!ratedUserId || !ratingType) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  try {
    const ratingSnapshot = await db
      .collection('users')
      .doc(ratedUserId)
      .collection('ratings')
      .doc(ratingType)
      .get();

    if (!ratingSnapshot.exists) {
      return { found: false, rating: null };
    }

    const ratingData = ratingSnapshot.data();
    const reviews = ratingData?.reviews || [];

    // Find current user's review
    const myReview = reviews.find((review: any) => review.ratedBy === currentUserId);

    if (myReview) {
      return { found: true, rating: myReview };
    }

    return { found: false, rating: null };
  } catch (error) {
    console.error('Error getting my rating:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get rating'
    );
  }
});
