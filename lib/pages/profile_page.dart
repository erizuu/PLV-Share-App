import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'profile_settings_page.dart';
import 'rating_service.dart';
import 'rating_dialog.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // If null, shows current user's profile
  final String? userName;
  final String? userPhotoUrl;
  final String? ratingType; // 'lender' or 'borrower' for rating context
  final String? transactionId; // Transaction ID for rating context

  const ProfilePage({
    super.key,
    this.userId,
    this.userName,
    this.userPhotoUrl,
    this.ratingType,
    this.transactionId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RatingService _ratingService = RatingService();

  late String userId; // The user whose profile we're viewing
  bool isOwnProfile = false;
  String _selectedRatingType = 'borrower'; // Toggle for own profile rating view

  Map<String, dynamic>? userData;
  int sharedCount = 0;
  int borrowedCount = 0;
  double trustScore = 0.0;
  int successfulExchanges = 0;
  List<String> earnedBadges = [];
  bool isLoading = true;
  Map<String, dynamic>? lenderRating;
  Map<String, dynamic>? borrowerRating;

  @override
  void initState() {
    super.initState();
    // Determine which user profile to load
    userId = widget.userId ?? currentUser?.uid ?? '';
    isOwnProfile = (widget.userId == null || widget.userId == currentUser?.uid);
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Get user profile data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>?;
      }

      // Get items shared count (items where user is lender)
      QuerySnapshot sharedItems = await _firestore
          .collection('items')
          .where('lenderId', isEqualTo: userId)
          .get();

      // Get items borrowed count (transactions where user is borrower and completed)
      QuerySnapshot borrowedTransactions = await _firestore
          .collection('transactions')
          .where('borrowerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Get successful exchanges (completed transactions as lender)
      QuerySnapshot lenderTransactions = await _firestore
          .collection('transactions')
          .where('lenderId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Calculate trust score (based on ratings from borrowers)
      double averageRating = 0.0;
      int ratedCount = 0;

      if (lenderTransactions.docs.isNotEmpty) {
        double totalRating = 0.0;

        for (var transaction in lenderTransactions.docs) {
          var data = transaction.data() as Map<String, dynamic>;
          if (data.containsKey('borrowerRating') &&
              data['borrowerRating'] != null) {
            totalRating += (data['borrowerRating'] as num).toDouble();
            ratedCount++;
          }
        }

        if (ratedCount > 0) {
          averageRating = totalRating / ratedCount;
        }
      }

      // If no ratings yet, default to 5.0 but show as new user
      trustScore = averageRating > 0 ? averageRating : 5.0;
      sharedCount = sharedItems.docs.length;
      borrowedCount = borrowedTransactions.docs.length;
      successfulExchanges = lenderTransactions.docs.length;

      // Determine earned badges based on actual activity
      List<String> badges = [];

      // Always on Time badge (check if user has no late returns as borrower)
      if (borrowedCount > 0) {
        QuerySnapshot lateReturns = await _firestore
            .collection('transactions')
            .where('borrowerId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .where('isLate', isEqualTo: true)
            .get();

        if (lateReturns.docs.isEmpty) {
          badges.add('Always on Time');
        }
      }

      // Quick Responder badge (check response time as lender)
      if (sharedCount >= 3) {
        QuerySnapshot quickResponses = await _firestore
            .collection('transactions')
            .where('lenderId', isEqualTo: userId)
            .where('responseTime', isLessThan: 3600) // Responded within 1 hour
            .get();

        if (quickResponses.docs.length >= 3) {
          badges.add('Quick Responder');
        }
      }

      // Trusted Lender badge (if has 5+ successful exchanges)
      if (successfulExchanges >= 5) {
        badges.add('Trusted Lender');
      }

      // First Exchange badge
      if (successfulExchanges >= 1) {
        badges.add('First Exchange');
      }

      if (mounted) {
        setState(() {
          earnedBadges = badges;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String getFullName() {
    if (userData != null && userData!.containsKey('fullName')) {
      return userData!['fullName'] ?? 'No Name';
    }
    return currentUser?.displayName ?? 'User';
  }

  String getEmail() {
    return currentUser?.email ?? 'No email';
  }

  String getCourse() {
    if (userData != null && userData!.containsKey('course')) {
      return userData!['course'] ?? 'No Course';
    }
    return 'No Course';
  }

  String getSection() {
    if (userData != null && userData!.containsKey('section')) {
      return userData!['section'] ?? 'No Section';
    }
    return 'No Section';
  }

  String getSchoolId() {
    if (userData != null && userData!.containsKey('schoolId')) {
      return userData!['schoolId'] ?? 'No School ID';
    }
    return 'No School ID';
  }

  String getVerificationStatus() {
    if (userData != null && userData!.containsKey('verificationStatus')) {
      return userData!['verificationStatus'] ?? 'pending';
    }
    return 'pending';
  }

  bool isTop10Percent() {
    return successfulExchanges >= 5;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Navigate to LoginPage and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Not logged in',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B4A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B4A)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Profile Info
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C3E50),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.03,
                  ),
                  child: Column(
                    children: [
                      // Settings/Options Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button if viewing other user
                          if (!isOwnProfile)
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            )
                          else
                            const SizedBox(width: 48),

                          // Settings Button (only for own profile)
                          if (isOwnProfile)
                            PopupMenuButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.settings, size: 20),
                                      SizedBox(width: 8),
                                      Text('Settings'),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfileSettingsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              image:
                                  (isOwnProfile
                                          ? currentUser?.photoURL
                                          : widget.userPhotoUrl) !=
                                      null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        isOwnProfile
                                            ? currentUser!.photoURL!
                                            : widget.userPhotoUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : const DecorationImage(
                                      image: AssetImage(
                                        'images/profile_placeholder.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child:
                                (isOwnProfile
                                        ? currentUser?.photoURL
                                        : widget.userPhotoUrl) ==
                                    null
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white70,
                                  )
                                : null,
                          ),
                          // Verification Badge
                          if (getVerificationStatus() == 'verified')
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Name and Details
                      Text(
                        getFullName(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getEmail(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${getCourse()} - ${getSection()}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getVerificationStatus() == 'verified'
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getVerificationStatus().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Lender Trust Score Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'LENDER TRUST SCORE',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trustScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'OUT OF 5',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < trustScore.floor()
                                      ? Icons.star
                                      : index < trustScore
                                      ? Icons.star_half
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            if (isTop10Percent())
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B4A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Top 10% of Campus Lenders',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              successfulExchanges > 0
                                  ? 'Based on $successfulExchanges successful exchange${successfulExchanges != 1 ? 's' : ''}'
                                  : 'No exchanges yet',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Section
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Row(
                  children: [
                    // Shared Stats
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$sharedCount',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SHARED',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Items provided to others',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),

                    // Borrowed Stats
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$borrowedCount',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'BORROWED',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Items used from campus',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // User Ratings Section
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating Type Selector for own profile
                    if (isOwnProfile)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedRatingType = 'borrower',
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedRatingType == 'borrower'
                                        ? const Color(0xFFFF6B4A)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Borrower Ratings',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedRatingType == 'borrower'
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedRatingType = 'lender',
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedRatingType == 'lender'
                                        ? const Color(0xFFFF6B4A)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Lender Ratings',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedRatingType == 'lender'
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Rating Cards
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: _ratingService.watchUserRating(
                        userId,
                        isOwnProfile
                            ? _selectedRatingType
                            : widget.ratingType ?? 'borrower',
                      ),
                      builder: (context, ratingSnap) {
                        final rating =
                            ratingSnap.data?['averageRating'] as num? ?? 0.0;
                        final count =
                            ratingSnap.data?['totalRatings'] as int? ?? 0;
                        final ratingTypeLabel =
                            (isOwnProfile
                                    ? _selectedRatingType
                                    : widget.ratingType ?? 'borrower') ==
                                'lender'
                            ? 'Lender'
                            : 'Borrower';

                        return Row(
                          children: [
                            // Primary Rating Display
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < rating.floor()
                                              ? Icons.star
                                              : index < rating
                                              ? Icons.star_half
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ratingTypeLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '($count reviews)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Rate Button or Show My Rating (only when viewing another user's profile with context)
              if (!isOwnProfile && widget.ratingType != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: _ratingService.getMyRatingFor(
                    userId,
                    widget.ratingType ?? 'borrower',
                  ),
                  builder: (context, snapshot) {
                    final myRating = snapshot.data;
                    final alreadyRated = myRating != null;

                    if (alreadyRated && myRating != null) {
                      // Show my existing rating
                      final rating =
                          (myRating['rating'] as num?)?.toDouble() ?? 0.0;
                      final feedback = myRating['feedback'] ?? '';

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.02,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF6B4A),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Your Rating',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < rating.floor()
                                        ? Icons.star
                                        : index < rating
                                        ? Icons.star_half
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                feedback,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Show rate button
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.02,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final String ratingTypeToUse =
                                  widget.ratingType ?? 'borrower';
                              final String transactionIdToUse =
                                  widget.transactionId ?? '';

                              showDialog(
                                context: context,
                                builder: (context) => RatingDialog(
                                  ratedUserId: userId,
                                  ratedUserName:
                                      widget.userName ?? getFullName(),
                                  ratingType: ratingTypeToUse,
                                  transactionId: transactionIdToUse,
                                ),
                              );
                            },
                            icon: const Icon(Icons.star, color: Colors.white),
                            label: Text(
                              'Rate as ${widget.ratingType == 'lender' ? 'Lender' : 'Borrower'}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B4A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),

              // Other Reviews Section
              if (!isOwnProfile && widget.ratingType != null)
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ratingService.getUserReviews(
                    userId,
                    widget.ratingType ?? 'borrower',
                  ),
                  builder: (context, snapshot) {
                    final allReviews = snapshot.data ?? [];
                    // Get reviews from other users (not current user)
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    final otherReviews = allReviews
                        .where((review) => review['ratedBy'] != currentUserId)
                        .toList();

                    if (otherReviews.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Other Reviews (${otherReviews.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: otherReviews.length > 2
                                ? 2
                                : otherReviews.length,
                            itemBuilder: (context, index) {
                              final review = otherReviews[index];
                              final rating =
                                  (review['rating'] as num?)?.toDouble() ?? 0.0;
                              final feedback = review['feedback'] ?? '';
                              final raterName =
                                  review['ratedByName'] ?? 'Anonymous';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            raterName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2C3E50),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < rating.floor()
                                                  ? Icons.star
                                                  : i < rating
                                                  ? Icons.star_half
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 14,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      feedback,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (otherReviews.length > 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) {
                                      return DraggableScrollableSheet(
                                        expand: false,
                                        builder: (context, scrollController) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'All Reviews (${otherReviews.length})',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: ListView.builder(
                                                  controller: scrollController,
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  itemCount:
                                                      otherReviews.length,
                                                  itemBuilder: (context, index) {
                                                    final review =
                                                        otherReviews[index];
                                                    final rating =
                                                        (review['rating']
                                                                as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                    final feedback =
                                                        review['feedback'] ??
                                                        '';
                                                    final raterName =
                                                        review['ratedByName'] ??
                                                        'Anonymous';

                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                raterName,
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .amber
                                                                      .withOpacity(
                                                                        0.2,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .star,
                                                                      color: Colors
                                                                          .amber,
                                                                      size: 14,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 4,
                                                                    ),
                                                                    Text(
                                                                      rating
                                                                          .toStringAsFixed(
                                                                            1,
                                                                          ),
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Row(
                                                            children: List.generate(5, (
                                                              i,
                                                            ) {
                                                              return Icon(
                                                                i <
                                                                        rating
                                                                            .floor()
                                                                    ? Icons.star
                                                                    : i < rating
                                                                    ? Icons
                                                                          .star_half
                                                                    : Icons
                                                                          .star_border,
                                                                color: Colors
                                                                    .amber,
                                                                size: 16,
                                                              );
                                                            }),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            feedback,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey
                                                                  .shade800,
                                                              height: 1.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  'View all ${otherReviews.length} reviews',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B4A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              // Earned Badges Section
              if (earnedBadges.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earned Badges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: earnedBadges.map((badge) {
                          IconData iconData;
                          Color badgeColor = const Color(0xFFFF6B4A);

                          switch (badge) {
                            case 'Always on Time':
                              iconData = Icons.access_time;
                              break;
                            case 'Quick Responder':
                              iconData = Icons.flash_on;
                              break;
                            case 'Trusted Lender':
                              iconData = Icons.emoji_events;
                              badgeColor = Colors.amber;
                              break;
                            case 'First Exchange':
                              iconData = Icons.stars;
                              badgeColor = Colors.blue;
                              break;
                            default:
                              iconData = Icons.star;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
